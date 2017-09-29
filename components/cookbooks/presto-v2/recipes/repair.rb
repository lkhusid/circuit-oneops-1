#
# Cookbook Name:: presto
# Recipe:: repair

include_recipe "#{node['app_name']}::restart"
