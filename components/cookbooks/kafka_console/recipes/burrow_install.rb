#
# Cookbook Name:: kafka_console
# Recipe:: burrow_install
#
# Copyright 2015, @WalmartLabs
#
# All rights reserved - Do Not Redistribute
#

require 'json'

zookeeper_port='9091'
kafka_port='9092'


fqdn_metadata = nil
node.workorder.payLoad[:DependsOn].each do |dep|
  if dep["ciClassName"] =~ /Fqdn/
    fqdn_metadata = dep
    break
  end
end

if fqdn_metadata.nil?
  Chef::Log.error("no DependsOn Fqdn - exit -1")
  exit -1
end

kafka_fqdn = ''


if fqdn_metadata["ciAttributes"]["full_aliases"].nil? or fqdn_metadata["ciAttributes"]["full_aliases"].empty?
  kafka_fqdn = JSON.parse( fqdn_metadata["ciAttributes"]["entries"]).keys[-1]
else
  kafka_fqdn = JSON.parse(fqdn_metadata["ciAttributes"]["full_aliases"])
end


Chef::Log.info("kafka_fqdn= #{kafka_fqdn}")

payLoad = node.workorder.payLoad[:kafka].select { |cm| cm['ciClassName'].split('.').last == 'Kafka'}.first

use_external_zookeeper = payLoad["ciAttributes"]["use_external_zookeeper"]

if use_external_zookeeper.eql?("false")
  zookeeper_fqdn = kafka_fqdn
else
  zookeeper_fqdn = payLoad["ciAttributes"]["external_zk_url"]
end


local_vars= node.workorder.payLoad.OO_LOCAL_VARS

if local_vars[local_vars.index{|resource| resource[:ciName] == 'env_name'}][:ciAttributes][:value].nil? or local_vars[local_vars.index{|resource| resource[:ciName] == 'env_name'}][:ciAttributes][:value].empty? or local_vars[local_vars.index{|resource| resource[:ciName] == 'clustername'}][:ciAttributes][:value].empty? or local_vars[local_vars.index{|resource| resource[:ciName] == 'clustername'}][:ciAttributes][:value].nil?
  Chef::Log.error("No platform level variable for clustername and env_name - exit -1")
  exit -1
end

env_name = local_vars[local_vars.index{|resource| resource[:ciName] == 'env_name'}][:ciAttributes][:value]
kafka_cluster_name = "#{local_vars[local_vars.index{|resource| resource[:ciName] == 'clustername'}][:ciAttributes][:value]}.#{env_name}"

Chef::Log.info("kafka cluster name is...#{kafka_cluster_name}")
Chef::Log.info("kafka fqdn is...#{kafka_fqdn}")
Chef::Log.info("zookeeper fqdn is...#{zookeeper_fqdn}")


node.set[:kafka_console][:kafka_cluster_name]=kafka_cluster_name
Chef::Log.info("setting node[:kafka_console][:kafka_cluster_name]: #{node[:kafka_console][:kafka_cluster_name]}")

Chef::Log.info('Installing go package using Yum...')
yum_package 'go'
yum_package 'gpm'

burrowUrl = "$OO_CLOUD{nexus}/nexus/service/local/repositories/thirdparty/content/com/linkedin/burrow/1.0.0/burrow-1.0.0.tar.gz"

Chef::Log.info("Burrow URL : #{node[:kafka_console][:burrowUrl]}")

remote_file '/app/burrow.tar.gz' do
  source node[:kafka_console][:burrow_version]
  owner 'root'
  group 'root'
  mode '0755'
  action :create_if_missing
end

Chef::Log.info('Untar burrow.tar.gz ...')
bash "untar_burrow" do
  user "root"
  group "root"
  cwd "/app"
  code <<-EOH
    mkdir -p -m 755 godir/burrow/
    tar -zxvf /app/burrow.tar.gz -C godir/burrow/
  EOH
  not_if { ::File.exist?('/app/godir/burrow/bin') && ::File.exist?('/app/godir/burrow/src') && ::File.exist?('/app/godir/burrow/pkg')}
end

Chef::Log.info('gpm & go install...')
bash "gpm_go_install" do
  user "root"
  group "root"
  cwd "/app/godir/burrow/src/github.com/linkedin/Burrow"
  environment 'GOPATH' => "/app/godir/burrow/"
  code <<-EOH
    gpm install
    go install
  EOH
  not_if 'ps -ef | grep -v grep | grep -i burrow'
end

Chef::Log.info('Log directory creation...')
directory '/app/godir/burrow/log/' do
  owner 'root'
  group 'root'
  mode '0775'
  action :create
  recursive true
end

Chef::Log.info('Template for burrow configuration file...')
template 'burrow.cfg' do
  path '/app/godir/burrow/burrow.cfg'
  source 'burrow.cfg.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables({
     :zk_host             => zookeeper_fqdn,
     :zk_port             => zookeeper_port,
     :kafka_host          => kafka_fqdn,
     :kafka_port          => kafka_port,
     :kafka_cluster_name  => kafka_cluster_name
  })
  notifies :restart, 'service[burrow]'
end

Chef::Log.info('service component for burrow as a service...')
service 'burrow' do
  supports :status => true, :restart => true, :reload => true, :stop => true
  action :nothing
  subscribes :reload, 'template[burrow.service]', :immediately
end

Chef::Log.info('Template for burrow as a service...')
template 'burrow.service' do
  path '/etc/init.d/burrow'
  source 'burrow.service.erb'
  owner 'root'
  group 'root'
  mode '0755'
  notifies :enable, 'service[burrow]'
  notifies :start, 'service[burrow]'
  notifies :restart, 'service[burrow]'
end
