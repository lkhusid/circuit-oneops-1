# rubocop:disable LineLength
###############################################################################
# Cookbook Name:: enterprise_server
# Recipe:: dump_attributes
# Purpose:: This recipe is used to dump defaults and calculated values for
#           Tomcat and from the metadata
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
# Global attributes for Tomcat ITH
###############################################################################
Chef::Log.debug("maven_identifier: #{node['enterprise_server']['maven_identifier']}")
Chef::Log.debug("install_from: #{node['enterprise_server']['install_from']}")
Chef::Log.debug("server_type: #{node['enterprise_server']['global']['install_server_type']}")
Chef::Log.debug("major version: #{node['enterprise_server']['global']['install_version_major']}")
Chef::Log.debug("minor version: #{node['enterprise_server']['global']['install_version_minor']}")
Chef::Log.debug("server_user: #{node['enterprise_server']['global']['server_user']}")
Chef::Log.debug("server_group: #{node['enterprise_server']['global']['server_group']}")
Chef::Log.debug("environment_settings: #{node['enterprise_server']['global']['environment_settings']}")

###############################################################################
# Attributes for context.xml Configuration
###############################################################################
Chef::Log.debug("override_context_enabled: #{node['enterprise_server']['context']['override_context_enabled']}")
if (node['enterprise_server']['context']['override_context_enabled'] == 'true')
  Chef::Log.debug("context_es: #{node['enterprise_server']['context']['context_es']}")
end

###############################################################################
# Attributes for server.xml Configuration
###############################################################################
Chef::Log.debug("override_server_enabled: #{node['enterprise_server']['server']['override_server_enabled']}")
if (node['enterprise_server']['context']['override_context_enabled'] == 'true')
  Chef::Log.debug("server_es: #{node['enterprise_server']['server']['server_es']}")
end
Chef::Log.debug("http_nio_connector_enabled: #{node['enterprise_server']['server']['http_nio_connector_enabled']}")
Chef::Log.debug("port: #{node['enterprise_server']['server']['port']}")
Chef::Log.debug("https_nio_connector_enabled: #{node['enterprise_server']['server']['https_nio_connector_enabled']}")
Chef::Log.debug("ssl_port: #{node['enterprise_server']['server']['ssl_port']}")
Chef::Log.debug("max_threads: #{node['enterprise_server']['server']['max_threads']}")
Chef::Log.debug("advanced_security_options: #{node['enterprise_server']['server']['advanced_security_options']}")
Chef::Log.debug("tlsv11_protocol_enabled: #{node['enterprise_server']['server']['tlsv11_protocol_enabled']}")
Chef::Log.debug("tlsv12_protocol_enabled: #{node['enterprise_server']['server']['tlsv12_protocol_enabled']}")
Chef::Log.debug("advanced_nio_connector_config: #{node['enterprise_server']['server']['advanced_nio_connector_config']}")
Chef::Log.debug("autodeploy_enabled: #{node['enterprise_server']['server']['autodeploy_enabled']}")
Chef::Log.debug("http_methods: #{node['enterprise_server']['server']['http_methods']}")
Chef::Log.debug("enable_method_get: #{node['enterprise_server']['server']['enable_method_get']}")
Chef::Log.debug("enable_method_put: #{node['enterprise_server']['server']['enable_method_put']}")
Chef::Log.debug("enable_method_post: #{node['enterprise_server']['server']['enable_method_post']}")
Chef::Log.debug("enable_method_delete: #{node['enterprise_server']['server']['enable_method_delete']}")
Chef::Log.debug("enable_method_options: #{node['enterprise_server']['server']['enable_method_options']}")
Chef::Log.debug("enable_method_head: #{node['enterprise_server']['server']['enable_method_head']}")

###############################################################################
# Attributes set in the setenv.sh script
###############################################################################
Chef::Log.debug("java_options: #{node['enterprise_server']['java']['java_options']}")
Chef::Log.debug("system_properties: #{node['enterprise_server']['java']['system_properties']}")
Chef::Log.debug("startup_params: #{node['enterprise_server']['java']['startup_params']}")
Chef::Log.debug("mem_max: #{node['enterprise_server']['java']['mem_max']}")
Chef::Log.debug("mem_start: #{node['enterprise_server']['java']['mem_start']}")

###############################################################################
# Attributes to control log settings
###############################################################################
Chef::Log.debug("access_log_pattern: #{node['enterprise_server']['logs']['access_log_pattern']}")

###############################################################################
# Attributes for Tomcat instance startup and shutdown processes
###############################################################################
Chef::Log.debug("stop_time: #{node['enterprise_server']['startup_shutdown']['stop_time']}")
if node.workorder.rfcCi.ciAttributes.key?('pre_shutdown_command')
  Chef::Log.debug("pre_shutdown_command: #{node['enterprise_server']['startup_shutdown']['pre_shutdown_command']}")
end
if node.workorder.rfcCi.ciAttributes.key?('post_shutdown_command')
  Chef::Log.debug("post_shutdown_command: #{node['enterprise_server']['startup_shutdown']['post_shutdown_command']}")
end
if node.workorder.rfcCi.ciAttributes.key?('pre_startup_command')
  Chef::Log.debug("pre_startup_command: #{node['enterprise_server']['startup_shutdown']['pre_startup_command']}")
end
if node.workorder.rfcCi.ciAttributes.key?('post_startup_command')
  Chef::Log.debug("post_startup_command: #{node['enterprise_server']['startup_shutdown']['post_startup_command']}")
end
Chef::Log.debug("time_to_wait_before_shutdown: #{node['enterprise_server']['startup_shutdown']['time_to_wait_before_shutdown']}")
Chef::Log.debug("polling_frequency_post_startup_check: #{node['enterprise_server']['startup_shutdown']['polling_frequency_post_startup_check']}")
Chef::Log.debug("max_number_of_retries_for_post_startup_check: #{node['enterprise_server']['startup_shutdown']['max_number_of_retries_for_post_startup_check']}")

###############################################################################
# Tomcat variables not in metadata.rb
###############################################################################
Chef::Log.debug("webapp_install_dir: #{node['enterprise_server']['webapp_install_dir']}")
Chef::Log.debug("config_dir: #{node['enterprise_server']['config_dir']}")
Chef::Log.debug("instance_dir: #{node['enterprise_server']['instance_dir']}")
Chef::Log.debug("server_log_path: #{node['enterprise_server']['server_log_path']}")
Chef::Log.debug("webapp_link: #{node['enterprise_server']['webapp_link']}")
Chef::Log.debug("tmp_dir: #{node['enterprise_server']['tmp_dir']}")
Chef::Log.debug("tmp_link: #{node['enterprise_server']['tmp_link']}")
Chef::Log.debug("work_dir: #{node['enterprise_server']['work_dir']}")
Chef::Log.debug("work_link: #{node['enterprise_server']['work_link']}")
Chef::Log.debug("catalina_dir: #{node['enterprise_server']['catalina_dir']}")
Chef::Log.debug("catalina_link: #{node['enterprise_server']['catalina_link']}")
Chef::Log.debug("keystore_dir: #{node['enterprise_server']['keystore_dir']}")
Chef::Log.debug("keystore_link: #{node['enterprise_server']['keystore_link']}")
Chef::Log.debug("keystore_path: #{node['enterprise_server']['keystore_path']}")
Chef::Log.debug("context_dir: #{node['enterprise_server']['context_dir']}")
Chef::Log.debug("scripts_dir: #{node['enterprise_server']['scripts_dir']}")
Chef::Log.debug("keystore_pass: #{node['enterprise_server']['keystore_pass']}")
Chef::Log.debug("shutdown_port: #{node['enterprise_server']['shutdown_port']}")
Chef::Log.debug("use_security_manager: #{node['enterprise_server']['use_security_manager']}")
Chef::Log.debug("ssl_configured_ciphers: #{node['enterprise_server']['ssl_configured_ciphers']}")
Chef::Log.debug("java_home: #{node['java']['java_home']}")
Chef::Log.debug("home: #{node['enterprise_server']['home']}")
Chef::Log.debug("base: #{node['enterprise_server']['base']}")
Chef::Log.debug('key: This key will not be printed out here. Please log into the server to read the key.')
