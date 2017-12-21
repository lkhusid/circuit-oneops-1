#
# Cookbook Name:: Jolokia_proxy
# Recipe:: status
#


cmd = Mixlib::ShellOut.new("/etc/init.d/jolokia_proxy status")
cmd.run_command
#cmd.error!
#Chef::Log.info(cmd.inspect)
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")



