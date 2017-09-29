#
# Cookbook Name:: tomcat
# Recipe:: start
#

tomcat_service_name = tom_ver
ruby_block "Start tomcat service" do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_out!("service #{tomcat_service_name} start ",
               :live_stream => Chef::Log::logger)
  end
end
