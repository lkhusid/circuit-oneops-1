#
# Cookbook Name:: presto
# Recipe:: update
#
# Copyright 2016, Walmart Labs
#
# Apache License, Version 2.0
#


include_recipe "#{node['app_name']}::jce"

include_recipe "#{node['app_name']}::install"

include_recipe "#{node['app_name']}::start"
