#
# Cookbook Name:: mirrormaker
# Recipe:: default
#
# Copyright 2015, WalmartLabs
#
# All rights reserved - Do Not Redistribute
#
include_recipe "mirrormaker::check_input"
include_recipe "mirrormaker::rpm"

template "/etc/cron.d/delete_mirrormaker_logs" do
  source "delete_mirrormaker_logs.erb"
  owner "root"
  group "root"
  mode "0644"
end

directory node['mirrormaker'][:log_dir] do
  owner "#{node['mirrormaker'][:user]}"
  group "#{node['mirrormaker'][:group]}"
  action :create
end

directory node['mirrormaker'][:config_dir] do
  owner "#{node['mirrormaker'][:user]}"
  group "#{node['mirrormaker'][:group]}"
  action :create
end

template "#{node['mirrormaker'][:config_dir]}/mirrormaker.properties" do
  source "mirrormaker.properties.erb"
  owner "#{node['mirrormaker'][:user]}"
  group "#{node['mirrormaker'][:group]}"
  mode  '0664'
end

template "#{node['mirrormaker'][:config_dir]}/log4j.properties" do
    source "log4j.properties.erb"
    owner "#{node['mirrormaker'][:user]}"
    group "#{node['mirrormaker'][:group]}"
    mode  '0664'
end

directory node['mirrormaker'][:consumer_config_dir] do
  owner "#{node['mirrormaker'][:user]}"
  group "#{node['mirrormaker'][:group]}"
  action :create
end

ssl_properties = setup_ssl_get_props() #fetches ssl properties key, value pairs.
template "#{node['mirrormaker'][:consumer_config_dir]}/consumer.properties" do
  source "consumer.properties.erb"
  owner "#{node['mirrormaker'][:user]}"
  group "#{node['mirrormaker'][:group]}"
  mode  "0755"
  variables ({
  	:ssl_properties => ssl_properties
  })
  action :create
end

directory node['mirrormaker'][:producer_config_dir] do
  owner "#{node['mirrormaker'][:user]}"
  group "#{node['mirrormaker'][:group]}"
  action :create
end

template "#{node['mirrormaker'][:producer_config_dir]}/producer.properties" do
  source "producer.properties.erb"
  owner "#{node['mirrormaker'][:user]}"
  group "#{node['mirrormaker'][:group]}"
  mode  "0755"
  variables ({
  	:ssl_properties => ssl_properties
  })
  action :create
end

# use 80% system memory for mirrormaker JVM
max_heap = (node['memory']['total'].to_i / 1000 * 0.8).round

template "#{node['mirrormaker'][:init_dir]}/mirrormaker" do
  source "mirrormaker.erb"
  owner "#{node['mirrormaker'][:user]}"
  group "#{node['mirrormaker'][:group]}"
  mode  "0755"
  variables :max_heap => max_heap
end

# create "check_mirrormaker_lag.sh" script for nagios
template "/opt/nagios/libexec/check_mirrormaker_lag.sh" do
    source "check_mirrormaker_lag.sh.erb"
    owner "root"
    group "root"
    mode  '0755'
end

# create "get_mirrormaker_lag.sh" script for telegraf
template "/usr/local/kafka/bin/get_mirrormaker_lag.sh" do
    source "get_mirrormaker_lag.sh.erb"
    owner "root"
    group "root"
    mode  '0755'
end

# create "mirrormaker_status.sh" script for telegraf
template "/usr/local/kafka/bin/mirrormaker_status.sh" do
    source "mirrormaker_status.sh.erb"
    owner "root"
    group "root"
    mode  '0755'
end

# create "mirrormaker_logerrs.sh" script for telegraf
template "/usr/local/kafka/bin/mirrormaker_logerrs.sh" do
    source "mirrormaker_logerrs.sh.erb"
    owner "root"
    group "root"
    mode  '0755'
end
	
execute "create check_logfiles" do
	command "mkdir /var/tmp/check_logfiles"
	not_if{ File.exists?('/var/tmp/check_logfiles') } 
end

execute "change permission" do
	command "chown -R nagios:nagios /var/tmp/check_logfiles"
	only_if { File.exists?('/var/tmp/check_logfiles') } 
end

execute "start mirrormaker" do
	command "service mirrormaker restart"
end
