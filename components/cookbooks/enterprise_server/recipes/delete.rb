###############################################################################
# Cookbook Name:: enterprise_server
# Recipe:: delete
# Purpose:: This recipe is used to delete the Tomcat system by disabling the
#           service and deleting the directory
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
install_target_dir = node['enterprise_server']['install_target_dir']

execute "service enterprise-server stop" do
  returns [0,1,5]
end

directory "#{install_target_dir}" do
  recursive true
  action :delete
  only_if { ::Dir.exists?("#{install_target_dir}") }
end

#updated removed 9 added 1
execute "chkconfig --del #{install_target_dir}" do
  only_if { ::Dir.exists?("#{install_target_dir}") }
  returns [0,1]
end

if (node["platform"] == 'centos')
    Chef::Log.info("Uninstalling haveged...")
    yum_package 'haveged' do
          action    :remove
    end
end
