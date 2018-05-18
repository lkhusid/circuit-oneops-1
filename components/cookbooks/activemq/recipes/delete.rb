#
# Cookbook Name:: activemq
# Recipe:: delete
#

service "activemq" do
  provider Chef::Provider::Service::Init::Redhat
  action [:stop, :disable]
end

