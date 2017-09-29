
# install ansible

version = node.workorder.rfcCi.ciAttributes.ansible_version

ruby_block "Install ansible" do
	ver = version.eql?('latest') ? '' : "==#{version}"
	not_if { ::File.exists?('/bin/ansible-playbook') }
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell = Mixlib::ShellOut.new("#{node.python.pip_binary} install ansible#{ver}",
        :live_stream => Chef::Log::logger, :environment => {})
    shell.run_command
    shell.error!
  end
end

