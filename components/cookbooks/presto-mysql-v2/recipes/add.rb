#
# Cookbook Name:: presto_mysql
# Recipe:: add
#
# Copyright 2016, Walmart Labs
#
# Apache License, Version 2.0
#

configName = node['app_name']
configNode = node[configName]

directory '/usr/lib/presto/etc/catalog/' do
  owner 'presto'
  group 'presto'
  mode  '0755'
  recursive true
end

presto_catalog_file = '/usr/lib/presto/etc/catalog/' + configNode['connection_name'] + '.properties'

connector_config = { }

if (configNode['connector_config'] != nil)
  connector_config = JSON.parse(configNode['connector_config'])
end

template presto_catalog_file do
    source 'mysql.properties.erb'
    owner 'presto'
    group 'presto'
    mode '0755'
    variables ({
        :connection_url => configNode['connection_url'],
        :connection_user_id => configNode['connection_user_id'],
        :connection_password => configNode['connection_password'],
        :connector_config => connector_config
    })
end

include_recipe "#{node['app_name']}::restart"
