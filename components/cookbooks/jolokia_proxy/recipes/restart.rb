#
# Cookbook Name:: Jolokia_proxy
# Recipe:: restart
#
#
# 
service "jolokia_proxy" do
  provider Chef::Provider::Service::Init
  service_name 'jolokia_proxy'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end
