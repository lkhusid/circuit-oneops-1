# Info - Run the 'info' action
#
# This recipe determines the current directory status of the compute and returns it.

Chef::Log.info("Running #{node['app_name']}::info")

cmd = Mixlib::ShellOut.new("/usr/bin/adinfo")
cmd.run_command

Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")

Chef::Log.info("#{node['app_name']}::info completed")

