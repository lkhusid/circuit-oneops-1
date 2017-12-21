cmd = Mixlib::ShellOut.new("/etc/init.d/kafka-manager status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")


#cmd = Mixlib::ShellOut.new("/etc/init.d/burrow status")
#cmd.run_command
#Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
