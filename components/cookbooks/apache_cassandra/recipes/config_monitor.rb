
## cron and templates for monitor ##

template '/opt/nagios/libexec/nodetool_status.pl' do
  source 'nodetool_status.pl.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end

template '/opt/cassandra/nodetools.sh' do
  source 'nodetools.sh.erb'
  owner 'oneops'
  group 'oneops'
  mode '0755'
end

cookbook_file '/opt/cassandra/check_azure_fault_domain.py' do
  source 'check_azure_fault_domain.py'
  owner 'cassandra'
  group 'cassandra'
  mode '0777'
end

ruby_block 'CREATE CRON FOR NODETOOLS' do
  block do
    cmd = `sudo su - cassandra -c "crontab -l | grep -v nodetools.sh > /tmp/cron.tmp ; echo '*/5 * * * * /opt/cassandra/nodetools.sh > /tmp/nodetoolstatus.log 2>&1' >> /tmp/cron.tmp ; crontab /tmp/cron.tmp"`
    Chef::Log.info("Cron Nodetools : cmd :"+cmd)
  end
 only_if { ::File.exists?("/opt/cassandra/nodetools.sh")}
end
