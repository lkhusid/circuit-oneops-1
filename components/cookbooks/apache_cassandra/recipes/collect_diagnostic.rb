bash "Collect Diagnostics Data"  do
  code <<-EOH
       /opt/cassandra/bin/nodetool info    > /tmp/diagnostic.log 
       /opt/cassandra/bin/nodetool version  >> /tmp/diagnostic.log  
       /opt/cassandra/bin/nodetool status  >> /tmp/diagnostic.log   
       /opt/cassandra/bin/nodetool tpstats    >> /tmp/diagnostic.log   
       sar >> /tmp/diagnostic.log  
       df -kh >> /tmp/diagnostic.log  
       iostat -x >> /tmp/diagnostic.log  
       free -m >> /tmp/diagnostic.log  
       netstat -an >> /tmp/diagnostic.log  
       cat /etc/security/limits.conf >> /tmp/diagnostic.log  
       tar -cvf /tmp/diagnostic.tar /app/cassandra/log/system.log /tmp/diagnostic.log 
       gzip /tmp/diagnostic.tar

  EOH
 end

ruby_block "Cassandra Diagnostic"  do
  block do
    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_out!(" cat /tmp/diagnostics.log ; ls -lrt /tmp/diagnostic.* ",
               :user => 'root',
               :group => 'root',
               :live_stream => Chef::Log::logger)
end
end

