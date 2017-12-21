#
# Cookbook Name:: cassandra
# Recipe:: start
#
# Copyright 2012, Kloopz Inc
#
# All rights reserved - Do Not Redistribute
localIp = node[:ipaddress]

service "cassandra" do
  action :start
end

ruby_block "cassandra_running" do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    if !cassandra_running
        puts "***FAULT:FATAL=Cassandra isn't running"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e         
    end
  end
end

ruby_block "check_port_open" do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
     portNo = get_def_cqlsh_port
     port_open?(localIp, portNo)
  end
end
