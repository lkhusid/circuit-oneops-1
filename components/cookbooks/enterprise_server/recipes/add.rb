# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: enterprise_server
# Recipe:: add
# Purpose:: This recipe is used to do the initial setup of the Enterprise Server system
#     settings before the Tomcat binaries are installed onto the server.
#
# Copyright 2016, OneOps, All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################
###############################################################################
# Setup server User and Group
#   The server_user and server_group variables will be grabbed from the user
#     response in the metadata.rb file if different from the default values.
###############################################################################
require 'fileutils'

include_recipe 'enterprise_server::generate_variables'
include_recipe 'enterprise_server::dump_attributes'
install_root_dir = "#{node['enterprise_server']['install_root_dir']}"
install_target_dir = "#{node.set['enterprise_server']['install_target_dir']}"
server_group = "#{node['enterprise_server']['global']['server_group']}"
server_user = "#{node['enterprise_server']['global']['server_user']}"
jaas_configuration_content = "#{node['enterprise_server']['jaas_configuration_content']}"
local_vars = node.workorder.payLoad.OO_LOCAL_VARS
artifact_cxt = local_vars[local_vars.index { |resource| resource[:ciName] == 'deployContext' }][:ciAttributes][:value]
artifact_id = local_vars[local_vars.index { |resource| resource[:ciName] == 'artifactId' }][:ciAttributes][:value]
cluster_members = OneOpsHelper.get_nodes(node)

group "#{node['enterprise_server']['global']['server_group']}" do
  action :create
end

#create User
execute "useradd -m -g #{server_group} -d #{install_root_dir} #{server_user}" do
  returns [0,9]
end

###############################################################################
# Setup server.xml variables
#   1 - Set the protocol type to org.apache.coyote.http11.Http11Protocol
#   2 - Set the advanced_NIO_connector_config to either the user-entered value
#       or the default value
#   3 - Log the advanced_NIO_connector_config value to the Chef log
#   4 - Define the tomcat_version_name
#   5 - Set the max and min threads for Tomcat's threadpool
#   6 - See if a keystore is required
#   7 - If keystore is required, log that it is and get values for keystore
#       settings.
#   8 - Check if both HTTP and HTTPS connectors are disabled
#       If so, warn the customer that the instance may not be reachable
#   9 - If HTTPS is enabled, define the TLS protocols desired.
#       If HTTPS is enabled and the user manually disabled all TLS protocols
#       from the UI, TLSv1.2 is enabled.
###############################################################################

depends_on_keystore = node.workorder.payLoad.DependsOn.reject { |d| d['ciClassName'] !~ /Keystore/ }
if !depends_on_keystore.nil? && !depends_on_keystore.empty?
  Chef::Log.info("This does depend on keystore with filename: #{depends_on_keystore[0]['ciAttributes']['keystore_filename']} ")
  node.set['enterprise_server']['keystore_path'] = depends_on_keystore[0]['ciAttributes']['keystore_filename']
  node.set['enterprise_server']['keystore_pass'] = depends_on_keystore[0]['ciAttributes']['keystore_password']
  Chef::Log.info("Stashed keystore_path = #{node['enterprise_server']['keystore_path']}")
end

if node['enterprise_server']['server']['https_nio_connector_enabled'] == 'false' && node['enterprise_server']['server']['http_nio_connector_enabled'] == 'false'
  Chef::Log.warn('HTTP AND HTTPS ARE DISABLED. This may result in NO COMMUNICATION to the Enterprise Server instance.')
end

if node['enterprise_server']['server']['https_nio_connector_enabled'] == 'true'
  node.set['enterprise_server']['ssl_configured_protocols'] = ''
  if node['enterprise_server']['server']['tlsv11_protocol_enabled'] == 'true'
    node['enterprise_server']['ssl_configured_protocols'].concat('TLSv1.1,')
  end
  if node['enterprise_server']['server']['tlsv12_protocol_enabled'] == 'true'
    node['enterprise_server']['ssl_configured_protocols'].concat('TLSv1.2,')
  end
  node['enterprise_server']['ssl_configured_protocols'].chomp!(',')
  if node['enterprise_server']['ssl_configured_protocols'] == ''
    Chef::Log.warn('HTTPS is enabled, but all TLS protocols were disabled. Defaulting to TLSv1.2 only.')
    node.set['enterprise_server']['ssl_configured_protocols'] = 'TLSv1.2'
  end
end

###############################################################################
# Run Install Cookbook for Tomcat Binaries
###############################################################################
#including delete before add to fix issues with upgrading server version. before this when users upgrade,
# it doesn't clean existing libs resulting in bad deployment
# updated by vishal.bhardwaj0@walmartlabs.com Date:03/27/2017
if ::File.exists?("#{node['enterprise_server']['instance_dir']}/conf")
  puts "removing existing deployments"
  include_recipe 'enterprise_server::delete'
end

include_recipe "enterprise_server::pkg_install"

puts "adding enterprise server binary"
include_recipe 'enterprise_server::add_binary'

###############################################################################
# Setup Log Rotation
#   The logrotate.d script and these cron jobs will clean out Tomcat logs
#   older than seven days old.
###############################################################################

template '/etc/logrotate.d/enterprise-server' do
  source 'logrotate.erb'
  owner "root"
  group "root"
  mode '0644'
end

cron 'logrotatecleanup' do
  minute '0'
  command "ls -t1 #{node['enterprise_server']['server_log_path']}/access_log*|tail -n +7|xargs rm -r"
  mailto '/dev/null'
  action :create
end

cron 'logrotate' do
  minute '0'
  command 'sudo /usr/sbin/logrotate /etc/logrotate.d/enterprise-server'
  mailto '/dev/null'
  action :create
end

###############################################################################
# Setup Directories
###############################################################################
directory "#{node['enterprise_server']['webapp_install_dir']}" do
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  recursive true
  not_if "test -d #{node['enterprise_server']['webapp_install_dir']}"
end

link node['enterprise_server']['webapp_link'] do
  to node['enterprise_server']['webapp_install_dir']
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  not_if "test -d #{node['enterprise_server']['webapp_link']}"
end

directory "#{node['enterprise_server']['work_dir']}" do
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  recursive true
  not_if "test -d #{node['enterprise_server']['work_dir']}"
end

link node['enterprise_server']['work_link'] do
  to node['enterprise_server']['work_dir']
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  not_if "test -d #{node['enterprise_server']['work_link']}"
end

directory "#{node['enterprise_server']['scripts_dir']}" do
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  recursive true
  not_if "test -d #{node['enterprise_server']['scripts_dir']}"
end

directory "#{node['enterprise_server']['catalina_dir']}" do
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  recursive true
  not_if "test -d #{node['enterprise_server']['catalina_dir']}"
end

link node['enterprise_server']['catalina_link'] do
  to node['enterprise_server']['catalina_dir']
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  not_if "test -d #{node['enterprise_server']['catalina_link']}"
end

directory "#{node['enterprise_server']['context_dir']}" do
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  recursive true
  not_if "test -d #{node['enterprise_server']['context_dir']}"
end

link node['enterprise_server']['server_log_path'] do
  to node['enterprise_server']['server_log_path']
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0755'
  not_if "test -d #{node['enterprise_server']['server_log_path']}"
end

directory "#{node['enterprise_server']['keystore_dir']}" do
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  recursive true
  not_if "test -d #{node['enterprise_server']['keystore_dir']}"
end

link node['enterprise_server']['keystore_link'] do
  to node['enterprise_server']['keystore_dir']
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  not_if "test -d #{node['enterprise_server']['keystore_link']}"
end

directory "#{node['enterprise_server']['tmp_dir']}" do
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  recursive true
  not_if "test -d #{node['enterprise_server']['tmp_dir']}"
end

link node['enterprise_server']['tmp_link'] do
  to node['enterprise_server']['tmp_dir']
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  not_if "test -d #{node['enterprise_server']['tmp_link']}"
end

###############################################################################
#   Create Config Files From Templates
#   1 - server.xml
#   2 - context.xml
#   3 - tomcat-users.xml
#   4 - policy.d directory
#   6 - setenv.sh script
#   7 - tomcat.service
###############################################################################

template "#{node['enterprise_server']['instance_dir']}/conf/server.xml" do
  source 'server.xml.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0644'
end

template "#{node['enterprise_server']['instance_dir']}/conf/web.xml" do
  source 'web.xml.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0644'
end

template "#{node['enterprise_server']['instance_dir']}/conf/tomcat-users.xml" do
  source 'tomcat-users.xml.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
end

template "#{install_target_dir}/conf/logging.properties" do
  source 'logging.properties.erb'
  owner server_user
  group server_group
  mode 0640
end

file "#{install_target_dir}/conf/jaas.config" do
  content "#{jaas_configuration_content}"
  owner server_user
  group server_group
  mode 0640
end

directory "#{node['enterprise_server']['instance_dir']}/conf/policy.d" do
  action :create
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  not_if "test -d #{node['enterprise_server']['instance_dir']}/conf/policy.d"
end

template "#{node['enterprise_server']['instance_dir']}/bin/setenv.sh" do
  source 'setenv.sh.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0744'
  variables({
	   :cluster_member => cluster_members
  })
end

if !artifact_cxt.nil? && !artifact_cxt.empty? && !artifact_id.nil? && !artifact_id.empty?
  if (artifact_cxt == 'ROOT')
    directory "#{install_target_dir}/webapps/ROOT" do
      recursive true
      action :delete
    end
    link "#{install_target_dir}/webapps/#{artifact_cxt}" do
      to "#{install_root_dir}/#{artifact_id}/current"
    end
  end
end

template "#{node['enterprise_server']['scripts_dir']}/prestartup.sh" do
  source 'prestartup.sh.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0744'
  not_if { node['enterprise_server']['startup_shutdown']['pre_startup_command'].nil? || node['enterprise_server']['startup_shutdown']['pre_startup_command'].empty? }
end

template "#{node['enterprise_server']['scripts_dir']}/poststartup.sh" do
  source 'poststartup.sh.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0744'
  not_if { node['enterprise_server']['startup_shutdown']['post_startup_command'].nil? || node['enterprise_server']['startup_shutdown']['post_startup_command'].empty? }
end

template "#{node['enterprise_server']['scripts_dir']}/preshutdown.sh" do
  source 'preshutdown.sh.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0744'
  not_if {node['enterprise_server']['startup_shutdown']['pre_shutdown_command'].nil? || node['enterprise_server']['startup_shutdown']['pre_shutdown_command'].empty?}
end

template "#{node['enterprise_server']['scripts_dir']}/postshutdown.sh" do
  source 'postshutdown.sh.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0744'
  not_if {node['enterprise_server']['startup_shutdown']['post_shutdown_command'].nil? || node['enterprise_server']['startup_shutdown']['post_shutdown_command'].empty?}
end

template '/lib/systemd/system/enterprise-server.service' do
  source 'init_systemd.erb'
  cookbook 'enterprise_server'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0644'
  notifies :run, 'execute[Load systemd unit file]', :immediately
  only_if { node['platform_version'].to_f >= 7.0 }
end

template '/etc/init.d/enterprise-server' do
  source 'initd_to_systemd.erb'
  owner "#{node['enterprise_server']['global']['server_user']}"
  group "#{node['enterprise_server']['global']['server_group']}"
  mode '0755'
end

execute 'Load systemd unit file' do
  command 'systemctl daemon-reload'
  action :nothing
  only_if { node['platform_version'].to_f >= 7.0 }
end

###############################################################################
# Nagios Scripts
###############################################################################

template '/opt/nagios/libexec/check_tomcat.rb' do
  source 'check_tomcat.rb.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end

template '/opt/nagios/libexec/check_ecv.rb' do
  source 'check_ecv.rb.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end
template '/opt/nagios/libexec/check_es_response.rb' do
  source 'check_es_response.rb.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end

service 'enterprise-server' do
  service_name 'enterprise-server'
  supports :status => true, :start => true, :stop => true
  action [:enable]
end

###############################################################################
# Additional Recipes
#   These recipes will be called after the rest of the add.rb file is run.
###############################################################################

include_recipe 'enterprise_server::start'
