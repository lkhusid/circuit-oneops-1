#
# Cookbook Name:: tomcat
# Recipe:: stop

tomcat_service_name = tom_ver

ruby_block "Stop tomcat service" do
  only_if { File.exists?('/etc/init.d/' + tomcat_service_name) }
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)

    shell_out!("service #{tomcat_service_name} stop ",
               :live_stream => Chef::Log::logger)
  end
end
