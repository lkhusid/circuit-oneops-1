execute 'nodetool_drain' do
    command "/opt/cassandra/bin/nodetool drain"
    user 'cassandra'
    ignore_failure true
end

service 'cassandra' do
  action :stop
end

ruby_block "check_cassandra_down" do
    Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    block do
      Chef::Log.info("Waiting for Cassandra to stop");
      if cassandra_running
        #Attempt to forcibly kill it
        Chef::Log.warn('Cassandra process is still running, killing it')
        shell_out!("ps -fea | grep cassandra.pid | grep -v grep | awk '{print $2}' | xargs kill -9", :live_stream => Chef::Log::logger)
        if cassandra_running
          puts "***FAULT:FATAL=Cassandra hasn't stopped"
          e = Exception.new("no backtrace")
          e.set_backtrace("")
          raise e
        end
      end
      Chef::Log.info("Cassandra is stopped");
    end
end