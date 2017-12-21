#
# Cookbook Name:: cassandra
# Recipe:: config_directives
#
# Copyright 2015, @WalmartLabs.
require 'json'

v = node.default[:version]
#major_minor_version is the first 2 components of the version as a float e.g 2.1.12 = 2.1
major_minor_version = node.default[:version].to_f

cassandra_home = node.default[:cassandra_home]
cassandra_current = "#{cassandra_home}/current"

if node.workorder.has_key?("actionName") && node.workorder.actionName.eql?("upgrade")
  log4j_hash = JSON.parse(node.workorder.ci.ciAttributes.log4j_directives)
else
  log4j_hash = JSON.parse(node.workorder.rfcCi.ciAttributes.log4j_directives)
end
log4j_hash.each do |key,value|
 token = key.gsub('.', '_') 
 node.default[:"#{token}"] = value
end

template "#{cassandra_current}/conf/log4j-server.properties" do
  source "#{major_minor_version}/log4j-server.properties.erb"
  owner "cassandra"
  group "cassandra"
  mode 0644
  only_if { major_minor_version < 2.0 }
end

