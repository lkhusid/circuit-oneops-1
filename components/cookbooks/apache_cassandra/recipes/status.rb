#
# Cookbook Name:: cassandra
# Recipe:: status
#
# Copyright 2012, Kloopz Inc
#
# All rights reserved - Do Not Redistribute

status_result = `service cassandra status`
Chef::Log.info("service cassandra status: "+status_result)
if status_result.to_i != 0
  Chef::Log.warn("service cassandra status result_code: "+status_result.to_i.to_s)
end 
