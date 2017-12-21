# Cookbook Name:: kafka_console
# Recipe:: add
#
# Copyright 2014, @WalmartLabs
#
# All rights reserved - Do Not Redistribute

# install rpms

include_recipe "kafka_console::pkg_install"

include_recipe "kafka_console::set_domain_name"

# nginx setup
include_recipe "kafka_console::nginx"

# kafka-manager setup
include_recipe "kafka_console::kafka-manager"

include_recipe "kafka_console::restart"

bash "sleep for start" do
  user "root"
  group "root"
  code <<-EOH
    sleep 30
  EOH
end

# execute add_init_cluster.sh
execute 'run Add_init_cluster' do
  command "/etc/kafka-manager/add_init_cluster.sh"
  only_if {File.exists?("/etc/kafka-manager/add_init_cluster.sh")}
end

Chef::Log.info('Installing burrow...')
# include_recipe "kafka_console::burrow_install"
