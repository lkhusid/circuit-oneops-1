#
# Cookbook Name:: daemon
# Recipe:: delete
#
# Copyright 2016, Walmart Stores, Inc.
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

attrs = node.workorder.rfcCi.ciAttributes
service_name = attrs[:service_name]
pat = attrs[:pattern] || ''

service_type = nil
initService = "/etc/init.d/#{service_name}"
systemdService = "/usr/lib/systemd/system/#{service_name}.service"

if File.exist?(systemdService)
  service_type = "systemd"
elsif File.exist?(initService)
  service_type = "init"
end

if pat.empty?
  # set basic service
  service "#{service_name}" do
    provider Chef::Provider::Service::Init if service_type == "init" && node[:platform_family].include?("rhel")
    action [:disable,:stop]
  end

else
  # set pattern based service
  service "#{service_name}" do
    provider Chef::Provider::Service::Init if service_type == "init" && node[:platform_family].include?("rhel")
    pattern "#{pat}"
    action [:disable,:stop]
  end

end