# Cookbook Name:: kafka
# Recipe:: add
#
# Copyright 2014, @WalmartLabs
#
# All rights reserved - Do Not Redistribute

# install rpms
include_recipe "kafka::pkg_install"

# set up domain name if needed
include_recipe "kafka::set_domain_name"

if node.workorder.rfcCi.ciAttributes.use_external_zookeeper.eql?("false")
  # zookeeper setup
  include_recipe "kafka::zookeeper"
else
  include_recipe "kafka::cleanupzk"
end

# broker setup
include_recipe "kafka::broker"

if node.workorder.rfcCi.rfcAction == "add" || node.workorder.rfcCi.rfcAction == "replace"
  ruby_block "zkbrokerid" do
     block do
        Chef::Resource::RubyBlock.send(:include, Kafka::StartUtil)
        ensureBrokerIDInZK
       end
    end
end

# jmxtrans setup
include_recipe "kafka::jmxtrans"



