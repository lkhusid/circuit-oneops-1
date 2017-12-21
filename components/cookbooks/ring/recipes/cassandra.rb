dir=run_context.cookbook_collection["apache_cassandra"].root_dir
Chef::Log.info dir
require "#{dir}/libraries/cassandra_util"
nodes = node.workorder.payLoad.ManagedVia

if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
else
  ci = node.workorder.ci
end

local_vars= node[:workorder][:payLoad][:OO_LOCAL_VARS]
var = local_vars.detect {|r| r[:ciName] == 'skipDecommissionDownNodes'}
skipDecommissionDownNodes = var[:ciAttributes][:value] if var != nil

Chef::Log.info("skipDecommissionDownNodes is #{skipDecommissionDownNodes}")

extra = ""
if ci['ciAttributes'].has_key?("extra")
  extra = ci['ciAttributes']['extra']
end

# dns_record used for fqdn
dns_record = ""

nodetool = "nodetool"
cassandra_bin = ""

if node.platform =~ /redhat|centos/
  cassandra_bin = "/opt/cassandra/bin"
  nodetool = "#{cassandra_bin}/nodetool"
end
existing_nodes = []
new_nodes = false

# Build dns_record first to fix STRCASS-787
nodes.each do |compute|
  ip = compute[:ciAttributes][:private_ip]
  next if ip.nil? || ip.empty?
  if dns_record == ""
    dns_record = ip
  else
    dns_record += ",#{ip}"
  end
end
puts "***RESULT:dns_record=#{dns_record}"

nodes.each do |compute|
  ip = compute[:ciAttributes][:private_ip]
  next if ip.nil? || ip.empty?

  result = `#{nodetool} -h #{ip} netstats 2>&1`
  Chef::Log.info("result from nodetool -h #{ip} netstats: #{result} with return code of #{$?}")
  if result =~ /Mode: NORMAL/
    existing_nodes.push(ip)
    next
  end

  new_nodes = true
  ruby_block "#{compute[:ciName]}_ring_join" do
    Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
    block do
      cmd = "#{nodetool} -h #{ip} join 2>&1"
      Chef::Log.info(cmd)
      result  = `#{cmd}`

      if $? != 0 && (result =~ /already joined/) == nil
        Chef::Log.error(result)
        puts "***FAULT:FATAL=#{result}"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      end

      Chef::Log.info("Waiting for #{ip} to finish joining")
      start = Time.now.to_i
      while(node_joining(ip)) do
          if Time.now.to_i - start >= 4 * 60 && !receiving_streams(ip)
              puts "***FAULT:FATAL=Node #{ip} joining for more than 4 minutes with no active streams; it may be hung joining the ring; restarting Cassandra may fix it."
              e = Exception.new("no backtrace")
              e.set_backtrace("")
              raise e
          end
          sleep 5
      end
      Chef::Log.info("Waiting 30 seconds for ring state to settle after joining node")
      sleep 30
    end
  end

end

# Remove any deleted nodes that failed decommission.  Cassandra cookbooks will update seeds.
ruby_block "remove_dead_nodes" do
    Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
    block do
      all_node_ips = node.workorder.payLoad.RequiresComputes.collect { |v| v[:ciAttributes][:private_ip] }
      dem_nodes = nodetool_status();
      dead_nodes = dem_nodes.keys - all_node_ips
      unless dead_nodes.empty?
        Chef::Log.warn("Cluster has #{dead_nodes.length} potential dead node(s) that must be removed.  Will run a repair after removing.  Dead node(s): #{dead_nodes.join(',')}")
        removed = false 
        dead_nodes.each do |ip|
          Chef::Log.info("Node #{ip} is in #{dem_nodes[ip]['status']} status")
          next unless dem_nodes[ip]['status'].start_with?('D')
          host_id = dem_nodes[ip]['hostid']
          raise "Failed to determine hostid to remove node #{ip}" if (host_id == nil || host_id.strip() == '')
          cmd = "#{nodetool} removenode #{host_id} 2>&1"
          Chef::Log.info(cmd)
          result = `#{cmd}`
          unless $? == 0 || $? == 2  #exits with 2 if host id is not found
            Chef::Log.error(result)
            puts "***FAULT:FATAL=Failed to remove dead node #{ip}.  Manually remove any dead nodes and run a repair."
            e = Exception.new("no backtrace")
            e.set_backtrace("")
            raise e
          end
          removed = true
        end
        if removed
          cmd = "#{nodetool} repair -local 2>&1"
          Chef::Log.info(cmd)
          result = `#{cmd}`
          if $? != 0
            Chef::Log.error(result)
            puts "***FAULT:FATAL=nodetool repair failed, data may be inconsistent.  Manually remove any dead nodes and run a repair."
            e = Exception.new("no backtrace")
            e.set_backtrace("")
            raise e
          end
        end
      end
    end
    #STRCASS-434
    only_if { node.workorder.payLoad.has_key?('RequiresComputes') && skipDecommissionDownNodes == nil}
end

# assuming we've added some new nodes here.  So, lets make sure
# we run a nodetool cleanup on the nodes that were existing in the cluster
# to free up space
Chef::Log.info("new_nodes is #{new_nodes}")
Chef::Log.info("existing nodes: #{existing_nodes.inspect}")
if new_nodes
  Chef::Log.info("We have some new nodes being added to the cluster")
  existing_nodes.each do |ip|
    ruby_block "#{ip}_cleanup" do
      Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
      block do
        cmd = "#{nodetool} -h #{ip} cleanup 2>&1"
        Chef::Log.info(cmd)
        result  = `#{cmd}`
        if $? != 0
          Chef::Log.error("cleanup on node #{ip} failed with #{result}")
        end
      end
    end
  end
end


# keyspaces and other extra
unless extra.nil? || extra.empty?
  file "/tmp/cassandra-schema.txt" do
      owner "root"
      group "root"
      mode "0755"
      content "#{extra}"
      action :create
  end
  execute "extra" do
    command "#{cassandra_bin}cassandra-cli -host localhost -port 9160 -f /tmp/cassandra-schema.txt"
    action :run
    ignore_failure true
  end
end
