# Cookbook Name:: kafka
# Recipe:: zookeeper.rb
#
# Copyright 2014, @WalmartLabs
#
# All rights reserved - Do Not Redistribute

# Currently Zookeeper instance will be installed on every Kafka broker node
# However the role of Zookeeper could be "elector" or "observer"
# https://zookeeper.apache.org/doc/trunk/zookeeperObservers.html

# goal of having both electors and observers in one same Zookeeper cluster
# is to scale the Zookeeper read throughput without hurting write performance

# since only Zookeeper electors will form a quorum
# the tricky part is how to evenly distribute electors across clouds
# if more than one clouds are used in a deployment.
# For example, if the size of Zookeeper electors is 5 and the # of clouds is 2,
# then one cloud should have 2 electors and the other shoud have 3 electors.
# if the # of clouds is 3, two clouds have 2 electors and one cloud have 1 electors (5 = 2+2+1)

# most of the logics here is to do the above simple math calculation.

# create base config dir if it doesn't exist
zk_config_dir = node['kafka']['zk_config_dir']

directory "#{zk_config_dir}" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

brokerid, myid, zk_electors, zk_observers = get_server_id_and_internal_zookeeper_electors

template_variables = {
  :zookeeper_electors   => zk_electors,
  :zookeeper_observers   => zk_observers,
  :myid              => myid,
}

full_hostname = get_full_hostname(node[:hostname])

# if the current node is classified as elector
# use elector property template to populate Zookeeper config file
if zk_electors.include? full_hostname
  template "#{zk_config_dir}/zookeeper.properties" do
    source "zookeeper_elector.properties.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables template_variables
  end
else
  template "#{zk_config_dir}/zookeeper.properties" do
    source "zookeeper_observer.properties.erb"
    owner 'root'
    group 'root'
    mode '0644'
    variables template_variables
  end
end

# log4j-zk.properties
template "#{zk_config_dir}/log4j-zk.properties" do
  source "log4j-zk.properties.erb"
  owner 'root'
  group 'root'
  mode  '0664'
end

# created zookeeper log dir
directory node['kafka']['zk_syslog_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# zookeeper install dir 
directory node['kafka']['zk_install_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# zookeeper log dir 
directory "#{node['kafka']['zk_install_dir']}/log" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# zookeeper data dir 
directory "#{node['kafka']['zk_install_dir']}/data" do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# zookeeper id
template "#{node['kafka']['zk_install_dir']}/data/myid" do
  source "myid.erb"
  owner 'root'
  group 'root'
  mode  '0664'
  variables template_variables
end

# zookeeper maint cron
template "/etc/cron.d/zookeeper_maintenance" do
  source "zookeeper_maintenance.erb"
  owner "root"
  group "root"
  mode  '0664'
end

# custom zookeeper init for heap size based on total local memory
totalmemory = node['memory']['total'].split('kB')[0].to_i/1024

Chef::Log.info("totalmemory: #{totalmemory}mb")
Chef::Log.info("jvm memory user input: #{node['kafka']['jvm_args']}")

# 1) zk heap size is between 512 mb and 6 gb;
# 2) if user specified kafka heap size, 80% of that size will be assigned as zk heap size
# 3) if user does not specify kafka heap size, 20% of total memory will be assigned to zk heap
# rules 2) and 3) are subject to the restriction of 1)

memoryspecified = node['kafka']['jvm_args'].to_s.empty? ? 0 : node['kafka']['jvm_args'].to_i * 0.8
heap_size = memoryspecified > 0 ? [memoryspecified, 512].max : [512, totalmemory * 0.20 ].max
heap_size = [heap_size, 6144].min

Chef::Log.info("heap_size for zk : #{heap_size.to_i}mb")

template "/etc/init.d/zookeeper" do
  source "zookeeper.erb"
  owner 'root'
  group 'root'
  mode '0755'
  variables :heap_size => heap_size.to_i
end

# zookeeper service
# To-do: implement rolling-restart zookeeper
service "zookeeper" do
  provider Chef::Provider::Service::Init
  service_name 'zookeeper'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :start
  only_if { node.workorder.rfcCi.rfcAction == "add" || node.workorder.rfcCi.rfcAction == "replace" } 
end

