
cmd = Mixlib::ShellOut.new("/etc/init.d/kafka status")
cmd.run_command
Chef::Log.info("Execution completed\n#{cmd.format_for_exception}")
