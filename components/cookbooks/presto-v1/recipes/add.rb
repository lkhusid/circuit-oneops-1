#
# Cookbook Name:: presto
# Recipe:: add
#
# Copyright 2016, Walmart Labs
#
# Apache License, Version 2.0
#

include_recipe "#{node['app_name']}::delete"

configName = node['app_name']
configNode = node[configName]

package 'mosh'
package 'screen'

user "presto" do
  comment "Presto user"
  home "/home/presto"
  system true
  action :create
end

# Make sure the presto user is in the group allowing SSH host key
# authentication
group "ssh_keys" do
    append true
    action :modify
    members "presto"
end

if configNode.has_key?('enable_ssl') && configNode['enable_ssl'] != nil && configNode['enable_ssl'] != "" && (configNode['enable_ssl'] == 'true')
  Chef::Log.info("Installing with SSL")
else
  Chef::Log.info("Not using SSL")
end

include_recipe "#{node['app_name']}::jce"

include_recipe "#{node['app_name']}::install"

include_recipe "#{node['app_name']}::start"
