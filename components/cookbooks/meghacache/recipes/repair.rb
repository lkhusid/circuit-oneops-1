cmd = Mixlib::ShellOut.new("systemctl status mcrouter.service")
cmd.run_command
if cmd.format_for_exception.include? "NOT running"
  include_recipe "mcrouter::start"
end

cmd = Mixlib::ShellOut.new("systemctl status memcached.service")
cmd.run_command
if cmd.format_for_exception.include? "NOT running"
    include_recipe "memcached::start"
end
