# configure pip.conf

file '/etc/pip.conf' do
	content node.workorder.rfcCi.ciAttributes.pip_proxy_content
	action :create_if_missing
end

# install pip

ruby_block "Install pip" do
	not_if { ::File.exists?(node.python.pip_binary) }
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell = Mixlib::ShellOut.new("#{node['python']['binary']} /etc/ansible/script/get-pip.py", :live_stream => Chef::Log::logger, :environment => {})
  	shell.run_command
  	shell.error!
  end
end

# install pip module 

ruby_block "Install module retrying" do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell = Mixlib::ShellOut.new("#{node.python.pip_binary} install retrying",
        :live_stream => Chef::Log::logger, :environment => {})
    shell.run_command
    shell.error!
  end
end

