#
# Cookbook Name:: presto
# Recipe:: status
#

cmd = Mixlib::ShellOut.new("/etc/init.d/presto status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
