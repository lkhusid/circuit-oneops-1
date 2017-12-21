# cassandra replace
require 'json'
ip_changed = node.workorder.rfcCi.ciAttributes.node_ip != node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]
ci = node.workorder.has_key?("rfcCi")?node.workorder.rfcCi : node.workorder.ci
cfg_json = JSON.parse(ci.ciAttributes.config_directives)
data_file_directories = ["#{node[:cassandra_home]}/data"]
if cfg_json.include?('data_file_directories')
  data_file_directories = JSON.parse(cfg_json['data_file_directories'])
end

commit_log_dir = "#{node[:cassandra_home]}/commitlog"
if cfg_json.include?('commitlog_directory')
  commit_log_dir = cfg_json['commitlog_directory']
end

execute "kill_process" do
  command "pkill -9 -f CassandraDaemon"
  returns [0,1]
end

#Don't delete directories for replace (might be external storage)
=begin
(data_file_directories + [commit_log_dir]).each do |dir|
  directory dir do
    action :delete
    recursive true
  end
end
=end

ruby_block "replace_address option" do
  block do
    Chef::Log.info("The IP address changed, will start with replace_address option.")
    node.set["cassandra_replace_option"] = "-Dcassandra.replace_address=#{node.workorder.rfcCi.ciAttributes.node_ip}"
  end
  only_if { ip_changed }
end

ruby_block "disable auto_bootstrap" do
  block do
    Chef::Log.info("The IP address did not change, will start with auto_bootstrap disabled.")
    node.set["cassandra_replace_option"] = "-Dcassandra.auto_bootstrap=false"
  end
  not_if { ip_changed }
end

include_recipe "apache_cassandra::add"

# The replace_address option will bootstrap the new node if hte IP changed,
# otherwise we start with auto_boostrap off and issue a rebuild from the local
# datacenter.
ruby_block "nodetool rebuild" do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    Chef::Log.info("Issuing nodetool rebuild to re-replicate data to this node.")
    dc = Cassandra::Util.nodetool_info()['Data Center']
    cmd_result = shell_out("/opt/cassandra/bin/nodetool rebuild #{dc}")
    cmd_result.error!
  end
  not_if { ip_changed }
end

include_recipe "apache_cassandra::update_seeds"

execute "Set CASSANDRA_HOME Ownership to Cassandra User" do
  command "chown -R cassandra:cassandra #{node[:cassandra_home]}"
end
