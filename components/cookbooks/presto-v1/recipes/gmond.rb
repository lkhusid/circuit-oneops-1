#
# Cookbook Name:: presto
# Recipe:: gmond
#
# Copyright 2016, @WalmartLabs
#
# All rights reserved - Do Not Redistribute
#

configName = node['app_name']
configNode = node[configName]

require 'json'

# install gmond
package 'ganglia-gmond'

# default config for ganglia gmond
cookbook_file "/etc/ganglia/gmond.conf" do
    source "gmond.conf"
    owner "root"
    group "root"
    mode "0644"
end

# define ganglia_servers here:
if (configNode['ganglia_servers'].nil? || configNode['ganglia_servers'].empty?)
  ganglia_servers = nil
else
  ganglia_servers = configNode['ganglia_servers'].split(',')
end

# ganglia config for yarn
template "/etc/ganglia/conf.d/delivered-gmond.conf" do
    source "delivered-gmond.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    variables :ganglia_servers => ganglia_servers
    notifies :restart, "service[gmond]"
end

# define service
service "gmond" do
    action [:start, :enable]
    supports :restart => true, :reload => true
end

metrics_port = configNode['http_port']
metrics_path = "v1/jmx/mbean/com.facebook.presto.execution:name=QueryManager"
presto_dir = "/usr/lib/presto"

prestoGmetric = "#{presto_dir}/presto_gmetric.sh"

# Create a template for the Presto metrics script
template prestoGmetric do
  source "presto-gmetric.sh.erb"
  owner "presto"
  group "presto"
  mode "0755"
  variables ({
    :metrics_port => metrics_port,
    :metrics_path => metrics_path
  })
end

prestoMetricCronD = "/etc/cron.d/presto_metrics"

# Schedule the Presto metrics script to run every minute if Ganglia is enabled
file prestoMetricCronD do
  content <<-EOF#!/bin/bash

SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin

* * * * * root #{presto_dir}/presto_gmetric.sh
EOF
  mode    '0644'
  owner   'root'
  group   'root'
  not_if { ganglia_servers.nil? }
end

# Delete the Presto metrics script entry if Ganglia is not enabled
file prestoMetricCronD do
  action :delete
  only_if { ganglia_servers.nil? }
end
