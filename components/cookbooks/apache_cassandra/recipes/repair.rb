SAFETY_FACTOR = 0.9
Chef::Log.info("Checking Cassandra for repair")

# Run nodetool info
# Restart if native transport or gossip are not active.

info = Cassandra::Util.nodetool_info()
unless !info.nil? && info['Gossip active'] == 'true' && info['Native Transport active'] == 'true'
  # node is down, for how long?
  begin
    ci = node.workorder.has_key?("rfcCi") ? node.workorder.rfcCi : node.workorder.ci
    down_seconds = Cassandra::Util.get_node_downtime_ms(ci[:ciAttributes][:node_ip], node) / 1000
  rescue Exception => e
    Chef::Log.info("get_node_downtime_ms threw #{e} #{e.backtrace}")
    down_since = Cassandra::Util.last_activity_time()
    down_seconds = Time.now - down_since
  end
  Chef::Log.info("Node has been down for #{down_seconds} seconds")

  min_gc_grace_seconds = Cassandra::Util.min_gc_grace(node)
  # Down past gc_grace, needs replaced
  if down_seconds > (min_gc_grace_seconds * SAFETY_FACTOR)
    # touch a file?
    puts "***FAULT:FATAL=Node has been down past the gc_grace period (#{min_gc_grace_seconds} seconds) and must be replaced"
    e = Exception.new('no backtrace') 
    e.set_backtrace('')
    raise e
  end

  Chef::Log.info("Restarting Cassandra")
  include_recipe 'apache_cassandra::restart'

  # Down past hint window, needs a repair
  yaml = YAML::load_file('/opt/cassandra/conf/cassandra.yaml')
  max_hint_window_in_ms = yaml['max_hint_window_in_ms'].to_i
  ruby_block "repair_primary_range" do
    Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
    block do
      Chef::Log.info("Node was down past max_hint_window_in_ms (#{max_hint_window_in_ms}), repairing this node's primary range; this will cause extra load on the cluster'")
      sleep 10 #let the node settle
      cmd = '/opt/cassandra/bin/nodetool repair -pr'
      r = shell_out(cmd, :live_stream => Chef::Log::logger, :timeout => 1200)
      r.error!
    end
    only_if { down_seconds > ((max_hint_window_in_ms / 1000) * SAFETY_FACTOR) }
  end

else
  Chef::Log.info('Cassandra appears to be running, not repairing.')
end
