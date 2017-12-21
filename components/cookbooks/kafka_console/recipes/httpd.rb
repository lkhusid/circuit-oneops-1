# Cookbook Name:: kafka_console
# Recipe:: httpd.rb
#
# Copyright 2014, @WalmartLabs
#
# All rights reserved - Do Not Redistribute

# update httpd.conf
template "/tmp/patch_httpd_vulnerability" do
  source "patch_httpd_vulnerability.erb"
end

execute "Update the httpd.conf" do
  user "root"
  command "cat /tmp/patch_httpd_vulnerability >> /etc/httpd/conf/httpd.conf"
end

execute "Remove patch_httpd_vulnerability" do
  command "rm /tmp/patch_httpd_vulnerability"
end

# httpd service
service "httpd" do
  provider Chef::Provider::Service::Systemd
  action [:start, :enable]
  supports :status => true, :restart => true, :reload => true
end