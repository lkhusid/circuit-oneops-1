###############################################################################
# Cookbook Name:: enterprise_server
# Recipe:: start
# Purpose:: This recipe is used to start the Tomcat binaries.
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
include_recipe 'enterprise_server::force-stop'

ruby_block "Start enterprise-server service" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("service enterprise-server start",
                 :live_stream => Chef::Log::logger)
    end
end
