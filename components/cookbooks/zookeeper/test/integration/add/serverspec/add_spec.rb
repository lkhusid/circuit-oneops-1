is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

conf_dir =  $node['workorder']['rfcCi']['ciAttributes']['conf_dir']
describe file(conf_dir) do
  it { should be_directory }
end

data_dir =  $node['workorder']['rfcCi']['ciAttributes']['data_dir']
describe file(data_dir) do
  it { should be_directory }
end

pid_dir = '/usr/lib/tmpfiles.d/zookeeper'
describe file(pid_dir) do
  it { should be_directory }
end

install_dir = $node['workorder']['rfcCi']['ciAttributes']['install_dir']
describe file(install_dir) do
  it { should be_directory }
end

journal_dir =  $node['workorder']['rfcCi']['ciAttributes']['journal_dir']
describe file(journal_dir) do
  it { should be_directory }
end

log_dir =  $node['workorder']['rfcCi']['ciAttributes']['log_dir']
describe file(log_dir) do
  it { should be_directory }
end

status_check = '/etc/init.d/zookeeper-server status'
describe command(status_check) do
  its(:stdout) { should contain('Mode') }
end

conf_file = conf_dir+'/zoo.cfg'
describe file(conf_file) do
  it { should be_file }
end

tickTime = 'tickTime='+$node['workorder']['rfcCi']['ciAttributes']['tick_time']
initLimit = 'initLimit='+$node['workorder']['rfcCi']['ciAttributes']['initial_timeout_ticks']
syncLimit = 'syncLimit='+$node['workorder']['rfcCi']['ciAttributes']['sync_timeout_ticks']
maxClientCnxns = 'maxClientCnxns='+$node['workorder']['rfcCi']['ciAttributes']['max_client_connections']
maxSessionTimeout = 'maxSessionTimeout='+$node['workorder']['rfcCi']['ciAttributes']['max_session_timeout']
snapCount = 'snapCount='+$node['workorder']['rfcCi']['ciAttributes']['snapshot_trigger']
clientPort = 'clientPort='+$node['workorder']['rfcCi']['ciAttributes']['client_port']
autopurgesnapRetainCount = 'autopurge.snapRetainCount='+$node['workorder']['rfcCi']['ciAttributes']['autopurge_snapretaincount']
autopurgepurgeInterval = 'autopurge.purgeInterval='+$node['workorder']['rfcCi']['ciAttributes']['autopurge_purgeinterval']


describe file(conf_file) do
  it { should contain tickTime }
  it { should contain initLimit }
  it { should contain syncLimit }
  it { should contain maxClientCnxns }
  it { should contain maxSessionTimeout }
  it { should contain snapCount }
  it { should contain clientPort }
  it { should contain autopurgesnapRetainCount }
  it { should contain autopurgepurgeInterval }
end

listen_port = $node['workorder']['rfcCi']['ciAttributes']['client_port']
describe port(listen_port) do
  it { should be_listening }
end

nodes = $node['workorder']['payLoad']['RequiresComputes']
nodes.each do |n|
  ip = n['ciAttributes']['public_ip']
  full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
  if full_hostname =~ /NXDOMAIN/
    describe file(conf_file) do
      it { should contain ip }
    end
  else
    describe file(conf_file) do
      it { should contain full_hostname }
    end
  end
end