#
# Cookbook Name:: Presto_swift
# Recipe:: delete
#
# Copyright 2016, Walmart Labs
#
# Apache License, Version 2.0
#

configName = node['app_name']
configNode = node[configName]

presto_catalog_file = '/etc/presto/catalog/' + configNode['connection_name'] + '.properties'

file presto_catalog_file do
    action :delete
end

include_recipe "#{node['app_name']}::restart"
