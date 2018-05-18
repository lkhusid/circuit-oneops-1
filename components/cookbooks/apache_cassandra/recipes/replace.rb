# cassandra replace
#
# Scenarios
# 1) Same ip, Fresh disk: set cassandra.replace_address=ip
# 2) Different ip, Fresh disk: set cassandra.replace_address=ip
# 3) Same ip, Preserved disk: Start normally.
# 4) Different ip, Preserved disk: Start normally.
#
# We're dependent on figuring out whether or not the data has been preserved (attached storage) or we
# have a fresh disk (ephemeral).  Also, the apache_cassandra component may have been replaced and NOT
# the compute regardless of the storage type.  Further confusing things, the node may have failed to
# fully start the first time with an empty disk, and on the next try, the disk will no longer be empty.
#
# We solve this problem by using a marker file.  The file is created if the first data directory is
# empty.  From then on, regardless of failed startups, if the file is present, we know to treat this
# node as one with a fresh disk.
#

require 'json'
ip_changed = node.workorder.rfcCi.ciAttributes.node_ip != node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]
ci = node.workorder.has_key?("rfcCi")?node.workorder.rfcCi : node.workorder.ci
cfg_json = JSON.parse(ci.ciAttributes.config_directives)
data_file_directories = ["#{node[:cassandra_home]}/data"]
marker_file = '/home/cassandra/replace_with_empty_data_dir_marker'
if cfg_json.include?('data_file_directories')
  data_file_directories = JSON.parse(cfg_json['data_file_directories'])
end

empty_data_dir = true
unless ::File.exist?(marker_file)
  data_file_directories.each do |dir|
    if ::Dir.exist?("#{dir}/system")
      empty_data_dir = false
      break
    end
  end
end

file marker_file do
  only_if { empty_data_dir }
end

commit_log_dir = "#{node[:cassandra_home]}/commitlog"
if cfg_json.include?('commitlog_directory')
  commit_log_dir = cfg_json['commitlog_directory']
end

#Ensure commit log dir is empty if the data directory is empty.
directory commit_log_dir do
  action :delete
  recursive true
  only_if { empty_data_dir }
end  

execute "kill_process" do
  command "pkill -9 -f CassandraDaemon"
  returns [0,1]
end

ruby_block "replace_address option" do
  block do
    Chef::Log.info("IP changed = #{ip_changed}, empty data dir = #{empty_data_dir}, will start with replace_address option.")
    node.set["cassandra_replace_option"] = "-Dcassandra.replace_address=#{node.workorder.rfcCi.ciAttributes.node_ip}"
  end
  only_if { empty_data_dir }
end

include_recipe "apache_cassandra::add"

file "/home/cassandra/replace_with_empty_data_dir_marker" do
  action :delete
end

include_recipe "apache_cassandra::update_seeds"
