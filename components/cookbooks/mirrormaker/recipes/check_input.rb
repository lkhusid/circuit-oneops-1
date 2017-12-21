#
# Cookbook Name:: mirrormaker
# Recipe:: check_input
#
# Copyright 2015, WalmartLabs
#
# All rights reserved - Do Not Redistribute
#

if (node['mirrormaker']['zookeeper_connect_for_consumer'] == "## Please specify the  zookeeper (server:port) connections ##")
    Chef::Log.error("Zookeeper connections string for consumer config is not set. ")
end

if (node['mirrormaker']['broker_list_for_producer'] == "## Please specify the brokers (server:port) connections ##")
    Chef::Log.error("The list of brokers for producer config is not set. ")
end

if (node['mirrormaker']['whitelist'] == "## Please specify the topic to mirror ##")
    Chef::Log.error("The list of topics to mirror is not set. ")
end



	
