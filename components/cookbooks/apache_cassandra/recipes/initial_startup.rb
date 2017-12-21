# update rfc
if node.workorder.has_key?("rfcCi")
	ci = node.workorder.rfcCi
	actionName = node.workorder.rfcCi.rfcAction
else
	ci = node.workorder.ci
	actionName = node.workorder.actionName
end

return if actionName !~ /add|replace/

private_ip = node[:ipaddress]

availability_mode = node.workorder.box.ciAttributes.availability 

cassandra_home = "#{node.default[:cassandra_home]}/current"

#Single availability
service 'cassandra' do
  action [ :enable, :start ]
  only_if { availability_mode == 'single' }
end

#Redundant
service 'cassandra' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :stop ]
  only_if { availability_mode != 'single' }
end

#wait while any of existing node is moving/joining/leaving
ruby_block "cluster_normal" do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    while(!cluster_normal?(node)) do
      Chef::Log.info("wait while any of existing node is moving/joining/leaving")
      sleep 30
    end
  end
  only_if { availability_mode != 'single' }
end

ruby_block "set_jvm_options" do
  block do
    node.set[:startup_jvm_opts] = "-Dcassandra.join_ring=false" if node.workorder.rfcCi.rfcAction == 'add' && !node[:initial_seeds].include?(private_ip)
    node.set[:startup_jvm_opts] = node['cassandra_replace_option'] if node.has_key?('cassandra_replace_option')
    unless node[:startup_jvm_opts].nil?
      fe = Chef::Util::FileEdit.new("#{cassandra_home}/conf/jvm.options")
      opts = node[:startup_jvm_opts].split()
      opts.each do |opt|
        name = opt.split(/=/, 2)[0]
        fe.search_file_delete_line("#{name}.*")
        fe.insert_line_if_no_match(name, opt)
      end
      fe.write_file
    end
  end
end

service "cassandra" do
  action [ :start ]
  not_if { availability_mode == 'single' }
end

ruby_block "cassandra_running" do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    unless cassandra_running
      puts "***FAULT:FATAL=Cassandra isn't running on #{private_ip}"
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    end
  end
end

ruby_block "check_port_open" do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    portNo = get_def_cqlsh_port
    port_open?(private_ip, portNo)
  end
end

#re-write the jvm.options file to remove the temorary startup options
template "#{cassandra_home}/conf/jvm.options" do
  source "jvm.options.erb"
  owner "cassandra"
  group "cassandra"
  mode 0644
end

# Set the superuser password on initial deployment.
# The password _cannot_ be changed on the cluster afterwards because OneOps makes no provision
# for determining old values for properties.  Therefore, after initial deployment, the password
# may only be set in OneOps to reflect the _actual_ password that's been set on the cluster 
# outside of OneOps.
ruby_block "set_superuser_password" do
  retries 3
  retry_delay 15
  block do
    #test with desired password
    Chef::Log.info("Checking password")
    r = `/opt/cassandra/bin/cqlsh -u '#{ci.ciAttributes.username}' -p '#{ci.ciAttributes.password}' --no-color -e "DESCRIBE CLUSTER;"`
    rc = $?.exitstatus
    Chef::Log.info("Password check exited with #{rc}, output: #{r}")
    if rc == 1 #failed with desired password
      Chef::Log.info("Setting superuser password")
      r = `/opt/cassandra/bin/cqlsh -u cassandra -p cassandra --no-color -e "ALTER USER '#{ci.ciAttributes.username}' WITH PASSWORD '#{ci.ciAttributes.password}';"`
      rc = $?.exitstatus
      Chef::Log.info("Superuser password set exited with #{rc}, output: #{r}")      
      Chef::Log.info("cqlsh rc #{rc} from setting superuser password: #{r}")    
      if rc != 0
        Chef::Log.warn("cqlsh output from setting superuser password: #{r}")
        puts "***FAULT:FATAL=Failed to set the superuser password.  Please ensure the cluster is up and running."
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      end
    end
  end
  only_if { ci.ciAttributes.has_key?("auth_enabled") && ci.ciAttributes.auth_enabled.eql?("true") && node[:initial_seeds].include?(private_ip) }
end