#
# Cookbook Name:: presto
# Recipe:: start
#

ruby_block 'Start presto service' do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        only_if { ::File.exists?('/etc/presto/node.properties') }
        shell_out!('service presto start',
                   live_stream: Chef::Log.logger)
    end
end
