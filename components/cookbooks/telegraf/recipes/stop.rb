case node.platform
when "windows"
  service "telegraf" do
    action [:stop]
    guard_interpreter :powershell_script
    only_if '(Get-Service | where-object { $_.name -eq "telegraf" }).count -ge 1'
  end
else
  #name = node['telegraf']['name']
  name = node.workorder.payLoad.RealizedAs[0].ciName
  initd_filename = 'telegraf'
  if(name.empty? || name.nil?)
    Chef::Log.info("instance name is not set. use default.")
  else
    initd_filename = initd_filename + "_" + name
  end

  ruby_block "stop telegraf" do
      block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!("service #{initd_filename} stop",
          :live_stream => Chef::Log::logger)
      end
  end
end
