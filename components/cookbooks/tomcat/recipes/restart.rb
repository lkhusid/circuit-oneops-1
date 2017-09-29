#
# Cookbook Name:: tomcat
# Recipe:: restart
#
tomcat_service_name = tom_ver

ruby_block "Restart tomcat service" do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_out!("service #{tomcat_service_name} restart ",
               :live_stream => Chef::Log::logger)
  end
end
