###############################################################################
# Cookbook Name:: enterprise_server
# Recipe:: stop
# Purpose:: This recipe is used to stop the Tomcat binaries.
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

ruby_block "Stop enterprise-server service" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("service enterprise-server stop",
        :live_stream => Chef::Log::logger)
    end
end

ruby_block "STOP_ENTERPRISE_SERVER" do
  block do
    pid = %x(sleep 5; ps -ef | grep enterprise-server | grep java | grep -v grep |tr -s ' ' |cut -d ' ' -f2)
    if !pid.nil? && !pid.empty?
      %x(kill -9 #{pid} )
      Chef::Log.info('Stopped process: ' + pid)
    end
  end
end

## adding this duplicate code to invoke stop service, as in some of the intermittent issues
# found by users of the pack version2, 1st instance of stop service fails and hence kill command is executed.
# the drawback of executing kill command is, service re-starts server automatically. If we re-execute
# stop service again, as below, it will not let auto-restart happen
# date: 03-02-2017 @author vbhard1 (vishal bhardwaj)
##
ruby_block "Stop enterprise-server service" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("service enterprise-server stop",
        :live_stream => Chef::Log::logger)
    end
end
