#
# Cookbook Name:: presto_swift
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

directory '/usr/lib/presto/lib/plugin/hive-hadoop2/' do
    owner 'root'
    group 'root'
    mode  '0755'
    recursive true
end

bash "install_hadoop-openstack" do
    code <<-EOL
    cp /opt/hadoop-*/share/hadoop/common/lib/hadoop-openstack-*.jar /usr/lib/presto/lib/plugin/hive-hadoop2/
    cp /opt/hadoop-*/share/hadoop/common/lib/hadoop-ceph-*.jar /usr/lib/presto/lib/plugin/hive-hadoop2/
    EOL
end

bash "install_commons-httpclient" do
    code <<-EOL
    cp /opt/hadoop-*/share/hadoop/common/lib/commons-httpclient-*.jar /usr/lib/presto/lib/plugin/hive-hadoop2/
    EOL
end

bash "install_jackson" do
    code <<-EOL
    cp /opt/hadoop-*/share/hadoop/common/lib/jackson-core-asl-*.jar /usr/lib/presto/lib/plugin/hive-hadoop2/
    cp /opt/hadoop-*/share/hadoop/common/lib/jackson-mapper-asl-*.jar /usr/lib/presto/lib/plugin/hive-hadoop2/
    cp /opt/hadoop-*/share/hadoop/common/lib/jackson-jaxrs-*.jar /usr/lib/presto/lib/plugin/hive-hadoop2/
    cp /opt/hadoop-*/share/hadoop/common/lib/jackson-xc-*.jar /usr/lib/presto/lib/plugin/hive-hadoop2/
    EOL
end

presto_catalog_file = '/usr/lib/presto/etc/catalog/' + configNode['connection_name'] + '.properties'

connector_config = { }

if (configNode['connector_config'] != nil)
  connector_config = JSON.parse(configNode['connector_config'])
end

template presto_catalog_file do
    source 'swift.properties.erb'
    owner 'presto'
    group 'presto'
    mode '0755'
    variables ({
        :connector_config => connector_config
    })
end

include_recipe "#{node['app_name']}::restart"
