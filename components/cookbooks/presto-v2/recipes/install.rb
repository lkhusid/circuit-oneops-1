#
# Cookbook Name:: presto
# Recipe:: install
#
# Copyright 2016, Walmart Labs
#
# Apache License, Version 2.0
#

require File.expand_path("../presto_helper.rb", __FILE__)

configName = node['app_name']
configNode = node[configName]

# Replace any $version placeholder variables present in the URL
# e.x: http://<mirror>/some/path/$version.rpm
install_url = configNode['presto_rpm_install_url'].gsub('$version', configNode['version'])
presto_cli_url = configNode['presto_client_install_url'].gsub('$version', configNode['version'])

Chef::Log.info("Installing Presto with #{install_url}")
Chef::Log.info("Presto CLI Install URL #{presto_cli_url}")

node_id = SecureRandom.uuid

node_prop_file = '/etc/presto/node.properties'

if File.file?(node_prop_file)
    File.open(node_prop_file, "r") do |file_handle|
      file_handle.each_line do |line|
        if line =~ /node.id/ then
            node_id = line.split("=")[1].gsub(/\n/, "")
            Chef::Log.info("Reusing node id of #{node_id}")
        end
      end
    end
end

include_recipe "#{node['app_name']}::delete"

ruby_block 'Install Presto RPM' do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        system("yum install -y '#{install_url}'")
    end
end

template '/opt/nagios/libexec/check_presto.rb' do
    source 'check_presto.rb.erb'
    owner 'oneops'
    group 'oneops'
    mode '0755'
end

directory configNode['data_directory_dir'] do
  owner 'presto'
  group 'presto'
  mode  '0755'
  recursive true
end

directory '/usr/lib/presto/var' do
  owner 'presto'
  group 'presto'
  mode  '0755'
  recursive true
end

directory '/usr/lib/presto/etc' do
  owner 'presto'
  group 'presto'
  mode  '0755'
end

directory '/etc/presto' do
  owner 'presto'
  group 'presto'
  mode  '0755'
  recursive true
end

if node['memory']['total'].to_i < 7000000
    puts "***FAULT:FATAL=The compute does not have enough memory.  Must be at least 7 GB"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
end

Chef::Log.info("Allocating #{configNode['presto_mem']} to Presto")

template node_prop_file do
    source 'node.properties.erb'
    owner 'presto'
    group 'presto'
    mode '0755'
    variables ({
        :environment => node.workorder.payLoad.Environment[0].ciName,
        :node_id => node_id,
        :data_directory_dir => configNode['data_directory_dir'],
        :query_max_memory => configNode['query_max_memory'],
        :query_max_memory_per_node => configNode['query_max_memory_per_node'],
    })
end

template '/etc/presto/jvm.config' do
    source 'jvm.config.erb'
    owner 'presto'
    group 'presto'
    mode '0755'
    variables ({
        :presto_mem => configNode['presto_mem'],
        :presto_thread_stack => configNode['presto_thread_stack'],
    })
end

template '/etc/presto/log.properties' do
    source 'log.properties.erb'
    owner 'presto'
    group 'presto'
    mode '0755'
    variables ({
        :presto_log_level => configNode['log_level'],
    })
end

include_recipe "#{node['app_name']}::gmond"
include_recipe "#{node['app_name']}::jmx"

remote_file '/usr/local/bin/presto-cli-executable.jar' do
    source presto_cli_url
    mode '0555'
    owner 'root'
    group 'root'
    action :create
end
