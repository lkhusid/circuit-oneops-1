# Cookbook Name:: kafka_console
# Recipe:: kafka-manager.rb
#
# Copyright 2014, @WalmartLabs
#
# All rights reserved - Do Not Redistribute

# delete default conf file if it exists
file "/etc/kafka-console/cluster.conf" do
    action :delete
    only_if { File.exists?("/etc/kafka-console/cluster.conf") }
end

# delete log file if it exists
file "/var/log/kafka-manager/kafka-manager.log" do
    action :delete
    only_if { File.exists?("/var/log/kafka-manager/kafka-manager.log") }
end

# delete log file if it exists
file "/var/log/kafka-manager/daemon.log" do
    action :delete
    only_if { File.exists?("/var/log/kafka-manager/daemon.log") }
end


# delete default conf file if it exists
file "/etc/kafka-manager/application.conf" do
    action :delete
    only_if { File.exists?("/etc/kafka-manager/application.conf") }
end

file "/etc/kafka-manager/logback.xml" do
  action :delete
  only_if { File.exists?("/etc/kafka-manager/logback.xml") }
end

# get the common prefix of hostname, e.g. kafka82-609889 is the common prefix of kafka82-609889-3-4783711, kafka82-609889-2-4783708, kafka82-609889-1-4783705
array = node[:hostname].split("-")
# NOTE: hostname_common_prefix will not be very helpful, unless making reverse DNS resolution work for each Kafka broker node
# by default, we use ".*" to do regex (which allows everything), rather than hostname_common_prefix.
hostname_common_prefix = array[0] + "-" + array[1] 

if node['kafka_console']['use_ptr'] == false
  fqdn = get_full_hostname(node.workorder.box.ciName)
else
  fqdn = get_full_hostname(node[:ipaddress])
end

payLoad = node.workorder.payLoad[:kafka].select { |cm| cm['ciClassName'].split('.').last == 'Kafka'}.first

use_external_zookeeper = payLoad["ciAttributes"]["use_external_zookeeper"]

if use_external_zookeeper.eql?("false")
  zookeeper_fqdn = fqdn
else
  zookeeper_fqdn = payLoad["ciAttributes"]["external_zk_url"]
end

directory "/etc/kafka-console" do
  owner "root"
  group "root"
  mode '0755'
  action :create
end

# kafka-manager.conf
template "/etc/kafka-manager/application.conf" do
  source "application.conf.erb"
  owner  'root'
  group  'root'
  mode   '0644'
  variables :zookeeper_fqdn => zookeeper_fqdn
end

template "/etc/kafka-manager/logback.xml" do
  source "logback.xml.erb"
  owner  'root'
  group  'root'
  mode   '0644'
end

# /etc/default/kafka-manager
template "/etc/default/kafka-manager" do
    source "jvm_args.erb"
    owner  'root'
    group  'root'
    mode   '0644'
end

# kafka-manager service
service "kafka-manager" do
  provider Chef::Provider::Service::Init
  service_name 'kafka-manager'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :start
end

kafka_version = payLoad["ciAttributes"]["version"]

# add the current Kafka cluster into kafka-manager
template "/etc/kafka-manager/add_init_cluster.sh" do
  source "add_init_cluster.sh.erb"
  owner  'root'
  group  'root'
  mode   '0755'
  variables ({
    :zookeeper_fqdn => zookeeper_fqdn,
    :kafka_version => kafka_version
  })
end
