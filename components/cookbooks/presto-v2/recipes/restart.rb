#
# Cookbook Name:: presto
# Recipe:: restart
#
ruby_block 'Restart presto service' do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
         shell_out!('service presto stop || true',
                    live_stream: Chef::Log.logger)
         shell_out!('ps -o pid -u presto | xargs kill -1 || true',
                    live_stream: Chef::Log.logger)
         shell_out!('service presto start',
                   live_stream: Chef::Log.logger)
    end
end
