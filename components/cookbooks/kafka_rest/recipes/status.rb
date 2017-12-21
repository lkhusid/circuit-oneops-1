cookbook_name = node.app_name.downcase

cmd = Mixlib::ShellOut.new("/etc/init.d/kafka-rest status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
