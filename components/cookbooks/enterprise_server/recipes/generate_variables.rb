# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: enterprise_server
# Recipe:: generate_attributes
# Purpose:: This recipe is used to generate defaults and calculated values for
#           Enterprise Server and from the metadata
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

##################################################################################################
# Global attributes
##################################################################################################
puts "Generating variables"
node.set['enterprise_server']['executor_min_spare_threads'] = 25
node.set['enterprise_server']['executor_prestart_min_spare_threads'] = false
node.set['enterprise_server']['global']['install_version_major'] = node.workorder.rfcCi.ciAttributes.install_version_major

if node['enterprise_server']['global']['install_version_major'].empty?
  Chef::Log.warn('install_version_major was empty: setting to 2')
  node.set['enterprise_server']['global']['install_version_major'] = '2'
end

node.set['enterprise_server']['global']['install_version_minor'] = node.workorder.rfcCi.ciAttributes.install_version_minor
if node['enterprise_server']['global']['install_version_minor'].empty?
  Chef::Log.warn('install_version_minor was empty: setting to 0.2')
  node.set['enterprise_server']['global']['install_version_minor'] = '0.2'
end

node.set['enterprise_server']['global']['server_user'] = node.workorder.rfcCi.ciAttributes.server_user
if node['enterprise_server']['global']['server_user'].empty?
  Chef::Log.warn('server_user was empty: setting to tomee')
  node.set['enterprise_server']['global']['server_user'] = 'tomee'
end

node.set['enterprise_server']['global']['server_group'] = node.workorder.rfcCi.ciAttributes.server_group
if node['enterprise_server']['global']['server_group'].empty?
  Chef::Log.warn('server_group was empty: setting to tomee')
  node.set['enterprise_server']['global']['server_group'] = 'tomee'
end

node.set['enterprise_server']['global']['environment_settings'] = node.workorder.rfcCi.ciAttributes.environment_settings

node.set['enterprise_server']['global']['server_mgt_port'] = node.workorder.rfcCi.ciAttributes.server_mgt_port
if node['enterprise_server']['global']['server_mgt_port'].empty?
  Chef::Log.warn('server_mgt_port was empty: setting to 8005')
  node.set['enterprise_server']['global']['server_mgt_port'] = '8005'
end

# Get Install Information from defaults
node.set['enterprise_server']['global']['install_root_dir'] = node.workorder.rfcCi.ciAttributes.install_root_dir
if node['enterprise_server']['global']['install_root_dir'].empty?
  Chef::Log.warn("install_root_dir was empty: setting to'/opt'")
  node.set['enterprise_server']['global']['install_root_dir'] = '/opt'
end
install_root_dir = "#{node['enterprise_server']['install_root_dir']}"

previous_install_type = "#{node['workorder']['rfcCi']['ciBaseAttributes']['install_server_type']}"
install_type = 'enterprise-server-tomee'

previous_version = "#{node['workorder']['rfcCi']['ciBaseAttributes']['install_version_major']}.#{node['workorder']['rfcCi']['ciBaseAttributes']['install_version_minor']}"
install_version = "#{node['enterprise_server']['install_version_major']}.#{node['enterprise_server']['install_version_minor']}"

#### externalization changes
cloud_name = node[:workorder][:cloud][:ciName]
puts "cloud name:#{cloud_name}"
mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
puts "Mirror setting ES: #{mirrors['enterprise_server']}"
node.set['enterprise_server']['install_from'] = mirrors['enterprise_server']
puts "Install from URL: #{node['enterprise_server']['install_from']}"


node.set['enterprise_server']['maven_identifier'] = "#{install_type}:#{install_version}:tgz"
node.set['enterprise_server']['install_target_dir'] = "#{install_root_dir}/enterprise-server"

node.set['enterprise_server']['install_target_symlink'] = "#{install_root_dir}/enterprise-server"
server_user = node['enterprise_server']['server_user']
server_group = node['enterprise_server']['server_group']

##################################################################################################
# Attributes for context.xml Configuration
##################################################################################################
node.set['enterprise_server']['context']['override_context_enabled'] = node.workorder.rfcCi.ciAttributes.override_context_enabled
if node.set['enterprise_server']['context']['override_context_enabled'] == 'true'
  node.set['enterprise_server']['context']['context_es'] = node.workorder.rfcCi.ciAttributes.context_es
end

##################################################################################################
# Attributes for server.xml Configuration
##################################################################################################
node.set['enterprise_server']['server']['override_server_enabled'] = node.workorder.rfcCi.ciAttributes.override_server_enabled
if node.set['enterprise_server']['context']['override_context_enabled'] == 'true'
  node.set['enterprise_server']['server']['server_es'] = node.workorder.rfcCi.ciAttributes.server_es
end

node.set['enterprise_server']['server']['http_nio_connector_enabled'] = node.workorder.rfcCi.ciAttributes.http_nio_connector_enabled
node.set['enterprise_server']['server']['port'] = node.workorder.rfcCi.ciAttributes.port
node.set['enterprise_server']['server']['https_nio_connector_enabled'] = node.workorder.rfcCi.ciAttributes.https_nio_connector_enabled
node.set['enterprise_server']['server']['ssl_port'] = node.workorder.rfcCi.ciAttributes.ssl_port
node.set['enterprise_server']['server']['max_threads'] = node.workorder.rfcCi.ciAttributes.max_threads
node.set['enterprise_server']['server']['advanced_security_options'] = node.workorder.rfcCi.ciAttributes.advanced_security_options
node.set['enterprise_server']['server']['tlsv11_protocol_enabled'] = node.workorder.rfcCi.ciAttributes.tlsv11_protocol_enabled
node.set['enterprise_server']['server']['tlsv12_protocol_enabled'] = node.workorder.rfcCi.ciAttributes.tlsv12_protocol_enabled
node.set['enterprise_server']['server']['advanced_nio_connector_config'] = node.workorder.rfcCi.ciAttributes.advanced_nio_connector_config
node.set['enterprise_server']['server']['autodeploy_enabled'] = node.workorder.rfcCi.ciAttributes.autodeploy_enabled
node.set['enterprise_server']['server']['http_methods'] = node.workorder.rfcCi.ciAttributes.http_methods
node.set['enterprise_server']['server']['enable_method_get'] = node.workorder.rfcCi.ciAttributes.enable_method_get
node.set['enterprise_server']['server']['enable_method_put'] = node.workorder.rfcCi.ciAttributes.enable_method_put
node.set['enterprise_server']['server']['enable_method_post'] = node.workorder.rfcCi.ciAttributes.enable_method_post
node.set['enterprise_server']['server']['enable_method_delete'] = node.workorder.rfcCi.ciAttributes.enable_method_delete
node.set['enterprise_server']['server']['enable_method_options'] = node.workorder.rfcCi.ciAttributes.enable_method_options
node.set['enterprise_server']['server']['enable_method_head'] = node.workorder.rfcCi.ciAttributes.enable_method_head

##################################################################################################
# Attributes set in the setenv.sh script
##################################################################################################
node.set['enterprise_server']['java']['java_options'] = node.workorder.rfcCi.ciAttributes.java_options
node.set['enterprise_server']['java']['system_properties'] = node.workorder.rfcCi.ciAttributes.system_properties
node.set['enterprise_server']['java']['startup_params'] = node.workorder.rfcCi.ciAttributes.startup_params

node.set['enterprise_server']['java']['mem_max'] = node.workorder.rfcCi.ciAttributes.mem_max
if node['enterprise_server']['java']['mem_max'].empty?
  Chef::Log.warn('mem_max was empty: setting to 1024M')
  node.set['enterprise_server']['java']['mem_max'] = '1024M'
end

node.set['enterprise_server']['java']['mem_start'] = node.workorder.rfcCi.ciAttributes.mem_start
if node['enterprise_server']['java']['mem_start'].empty?
  Chef::Log.warn('mem_start was empty: setting to 512M')
  node.set['enterprise_server']['java']['mem_start'] = '512M'
end

##################################################################################################
# Attributes to control log settings
##################################################################################################
node.set['enterprise_server']['logs']['access_log_pattern'] = node.workorder.rfcCi.ciAttributes.access_log_pattern
if node['enterprise_server']['logs']['access_log_pattern'].empty?
  Chef::Log.warn("access_log_pattern was empty: setting to '%h %l %u %t &quot;%r&quot; %s %b %D %F'")
  node.set['enterprise_server']['logs']['access_log_pattern'] = '%h %l %u %t &quot;%r&quot; %s %b %D %F'
end

node.set['enterprise_server']['logs']['server_log_path'] = node.workorder.rfcCi.ciAttributes.server_log_path
if node['enterprise_server']['logs']['server_log_path'].empty?
  Chef::Log.warn("server_log_path was empty: setting to '/log/enterprise-server'")
  node.set['enterprise_server']['logs']['server_log_path'] = '/log/enterprise-server'
end

node.set['enterprise_server']['logs']['access_log_prefix'] = node.workorder.rfcCi.ciAttributes.access_log_prefix
if node['enterprise_server']['logs']['access_log_prefix'].empty?
  Chef::Log.warn("access_log_prefix was empty: setting to 'access_log'")
  node.set['enterprise_server']['logs']['access_log_prefix'] = 'access_log'
end
node.set['enterprise_server']['logs']['access_log_suffix'] = node.workorder.rfcCi.ciAttributes.access_log_suffix
if node['enterprise_server']['logs']['access_log_suffix'].empty?
  Chef::Log.warn("access_log_suffix was empty: setting to 'access_log'")
  node.set['enterprise_server']['logs']['access_log_suffix'] = '.log'
end

node.set['enterprise_server']['logs']['access_log_file_date_format'] = node.workorder.rfcCi.ciAttributes.access_log_file_date_format
if node['enterprise_server']['logs']['access_log_file_date_format'].empty?
  Chef::Log.warn("access_log_file_date_format was empty: setting to 'yyyy-MM-dd'")
  node.set['enterprise_server']['logs']['access_log_file_date_format'] = 'yyyy-MM-dd'
end

node.set['enterprise_server']['logs']['server_log_level'] = node.workorder.rfcCi.ciAttributes.server_log_level
if node['enterprise_server']['logs']['server_log_level'].empty?
  Chef::Log.warn("server_log_level was empty: setting to 'WARNING'")
  node.set['enterprise_server']['logs']['server_log_level'] = 'WARNING'
end


##################################################################################################
# Attributes for Enterprise Server instance startup and shutdown processes
##################################################################################################
node.set['enterprise_server']['startup_shutdown']['stop_time'] = node.workorder.rfcCi.ciAttributes.stop_time
if node.workorder.rfcCi.ciAttributes.key?('pre_shutdown_command')
  node.set['enterprise_server']['startup_shutdown']['pre_shutdown_command'] = node.workorder.rfcCi.ciAttributes.pre_shutdown_command
end
if node.workorder.rfcCi.ciAttributes.key?('post_shutdown_command')
  node.set['enterprise_server']['startup_shutdown']['post_shutdown_command'] = node.workorder.rfcCi.ciAttributes.post_shutdown_command
end
if node.workorder.rfcCi.ciAttributes.key?('pre_startup_command')
  node.set['enterprise_server']['startup_shutdown']['pre_startup_command'] = node.workorder.rfcCi.ciAttributes.pre_startup_command
end
node.set['enterprise_server']['startup_shutdown']['time_to_wait_before_shutdown'] = node.workorder.rfcCi.ciAttributes.time_to_wait_before_shutdown
node.set['enterprise_server']['startup_shutdown']['polling_frequency_post_startup_check'] = node.workorder.rfcCi.ciAttributes.polling_frequency_post_startup_check
node.set['enterprise_server']['startup_shutdown']['max_number_of_retries_for_post_startup_check'] = node.workorder.rfcCi.ciAttributes.max_number_of_retries_for_post_startup_check
##################################################################################################
# Enterprise Server  variables not in metadata.rb
##################################################################################################
node.set['enterprise_server']['config_dir'] = "#{node['enterprise_server']['global']['install_root_dir']}"
node.set['enterprise_server']['instance_dir'] = "#{node['enterprise_server']['config_dir']}/enterprise-server"
# CLEAN ALL THE BELOW.
node.set['enterprise_server']['webapp_install_dir'] = "#{node['enterprise_server']['instance_dir']}/webapps"
node.set['enterprise_server']['webapp_link'] = "#{node['enterprise_server']['config_dir']}/webapps"
node.set['enterprise_server']['tmp_dir'] = "#{node['enterprise_server']['instance_dir']}/temp"
node.set['enterprise_server']['tmp_link'] = "#{node['enterprise_server']['config_dir']}/temp"
node.set['enterprise_server']['work_dir'] = "#{node['enterprise_server']['instance_dir']}/work"
node.set['enterprise_server']['work_link'] = "#{node['enterprise_server']['config_dir']}/work"
node.set['enterprise_server']['catalina_dir'] = "#{node['enterprise_server']['instance_dir']}/Catalina"
node.set['enterprise_server']['catalina_link'] = "#{node['enterprise_server']['config_dir']}/Catalina"
node.set['enterprise_server']['keystore_dir'] = "#{node['enterprise_server']['instance_dir']}/ssl"
node.set['enterprise_server']['keystore_link'] = "#{node['enterprise_server']['config_dir']}/ssl"
node.set['enterprise_server']['keystore_path'] = "#{node['enterprise_server']['instance_dir']}/ssl/keystore.jks"
node.set['enterprise_server']['context_dir'] = "#{node['enterprise_server']['catalina_dir']}/localhost"
node.set['enterprise_server']['scripts_dir'] = "#{node['enterprise_server']['config_dir']}/scripts"
node.set['enterprise_server']['keystore_pass'] = 'changeit'
node.set['enterprise_server']['shutdown_port'] = 8005
node.set['enterprise_server']['use_security_manager'] = false
node.set['enterprise_server']['ssl_configured_ciphers'] = 'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_CBC_SHA256,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_RSA_WITH_CAMELLIA_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_GCM_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA256,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA,TLS_RSA_WITH_AES_128_GCM_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA256,TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_CAMELLIA_128_CBC_SHA,TLS_DHE_RSA_WITH_SEED_CBC_SHA,TLS_RSA_WITH_SEED_CBC_SHA'
node.set['java']['java_home'] = '/usr'
node.set['enterprise_server']['home'] = '/usr/share/enterprise-server'
node.set['enterprise_server']['base'] = '/usr/share/enterprise-server'
node.set['enterprise_server']['manager']['key'] = SecureRandom.base64(21)
node.set['enterprise_server']['manager']['tomee_key'] = SecureRandom.base64(21)

node.set['enterprise_server']['global']['haveged_enabled'] = node.workorder.rfcCi.ciAttributes.haveged_enabled
