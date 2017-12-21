# Cookbook Name:: kafka_console
# Recipe:: nginx.rb
#
# Copyright 2014, @WalmartLabs
#
# All rights reserved - Do Not Redistribute

# delete default conf file if it exists
file "/etc/nginx/nginx.conf" do
  action :delete
  only_if { File.exists?("/etc/nginx/nginx.conf") }
end

# get the gmond host IPs (the first two IPs in Requires Compute that are not the IP of console-compute)
# the method is to loop each node and check & parse ciName to know if a node is console-compute
brokers = Array.new
nodes = node.workorder.payLoad.RequiresComputes
nodes.each do |n|
  # use ciName to filter out console-compute
  unless n[:ciName].include? "console"
   if node['kafka_console']['use_ptr'] == false
 	 fqdn = brokers.push(n[:ciAttributes][:dns_record])
   else
     fqdn = brokers.push(get_full_hostname(n[:ciAttributes][:dns_record])) 
   end
  end
end

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

var = {
  :brokers       => brokers,
  :fqdn              => fqdn,
  :zookeeper_fqdn  => zookeeper_fqdn,
}

# nginx.conf
template "/etc/nginx/nginx.conf" do
    source "nginx.conf.erb"
    owner  'root'
    group  'root'
    mode   '0644'
end

# conf.d/kafka.conf
template "/etc/nginx/conf.d/kafka.conf" do
  source "kafka.conf.erb"
  owner  'root'
  group  'root'
  mode   '0644'
  variables  var
end

# conf.d/kafka.template
template "/etc/nginx/conf.d/kafka.template" do
  source "kafka.template.erb"
  owner  'root'
  group  'root'
  mode   '0644'
  variables  var
end

# conf.d/kafka.conf
template "/etc/nginx/conf.d/kafka_ssl.conf" do
  source "kafka_ssl.conf.erb"
  owner  'root'
  group  'root'
  mode   '0644'
  variables  var
end

# conf.d/kafka.template
template "/etc/nginx/conf.d/kafka_ssl.template" do
  source "kafka_ssl.template.erb"
  owner  'root'
  group  'root'
  mode   '0644'
  variables  var
end

# if zookeeper is not external, deploy the zookeeper config file for Nginx
if use_external_zookeeper.eql?("false")
  # conf.d/zookeeper.conf
  template "/etc/nginx/conf.d/zookeeper.conf" do
    source "zookeeper.conf.erb"
    owner  'root'
    group  'root'
    mode   '0644'
    variables  var
  end

  # conf.d/zookeeper.template
  template "/etc/nginx/conf.d/zookeeper.template" do
    source "zookeeper.template.erb"
    owner  'root'
    group  'root'
    mode   '0644'
    variables  var
  end
end

# /etc/nginx/nginx_conf_sync_zk.py
template "/etc/nginx/nginx_conf_sync_zk.py" do
  source "nginx_conf_sync_zk.py.erb"
  owner  'root'
  group  'root'
  mode   '0644'
  variables  var
end

# nginx conf maint cron
template "/etc/cron.d/nginx_conf_maintenance" do
  source "nginx_conf_maintenance.erb"
  owner "root"
  group "root"
  mode  '0644'
end

# nginx service
execute 'install nginx' do
  command "systemctl start nginx"
end
