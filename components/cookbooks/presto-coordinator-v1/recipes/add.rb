#
# Cookbook Name:: presto_coordinator
# Recipe:: add
#
# Copyright 2016, Walmart Labs
#
# Apache License, Version 2.0
#

include_recipe "#{node['app_name']}::select_new_coordinator"
