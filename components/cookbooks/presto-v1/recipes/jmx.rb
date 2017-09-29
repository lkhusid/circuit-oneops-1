#
# Cookbook Name:: presto
# Recipe:: jmx
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

template "/usr/lib/presto/etc/catalog/jmx.properties" do
    source "jmx.properties.erb"
    owner "presto"
    group "presto"
    mode "0644"
    variables :jmx_mbeans => configNode['jmx_mbeans'],
              :jmx_dump_period => configNode['jmx_dump_period'],
              :jmx_max_entries => configNode['jmx_max_entries']
end
