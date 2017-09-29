name = node.workorder.payLoad.RealizedAs[0].ciName
initd_filename = 'filebeat'
if(name.empty? || name.nil?)
  Chef::Log.info("instance name is not set. use default.")
else
  initd_filename = initd_filename + "_" + name
end

ruby_block "check Filebeat status" do
    block do
      Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
      shell_out!("service #{initd_filename} status",
        :live_stream => Chef::Log::logger)
    end
end
