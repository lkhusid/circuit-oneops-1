#
# Cookbook Name:: tomcat
# Recipe:: status
#
tomcat_service_name = tom_ver

cmd = Mixlib::ShellOut.new("service #{tomcat_service_name} status")
cmd.run_command

Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
