ruby_block "Status enterprise_server service" do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_out!("service enterprise-server status",
               :live_stream => Chef::Log::logger)
  end
end
