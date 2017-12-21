#
# Cookbook Name:: mirrormaker
# Recipe:: status
#
cmd = Mixlib::ShellOut.new("/etc/init.d/mirrormaker status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")


