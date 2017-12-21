cmd = "
       /opt/cassandra/bin/nodetool info ;  
       /opt/cassandra/bin/nodetool version ;  
       /opt/cassandra/bin/nodetool status ;
       /opt/cassandra/bin/nodetool cfstats ;  
       /opt/cassandra/bin/nodetool compactionhistory ;  
       /opt/cassandra/bin/nodetool netstats ;  
       /opt/cassandra/bin/nodetool proxyhistograms ;  
       /opt/cassandra/bin/nodetool tpstats ;  
      "
puts "cmd = #{cmd}"
ruby_block "Cassandra Health Check"  do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_out!("#{cmd}",
               :user => 'root',
               :group => 'root',
               :live_stream => Chef::Log::logger)
  end
end
