# stop zookeeper if exist
service "zookeeper" do
  service_name 'zookeeper'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
  only_if { File.exists?('/etc/init.d/zookeeper') }
end

# delete zk service
file "/etc/init.d/zookeeper" do
    action :delete
    only_if { File.exists?("/etc/init.d/zookeeper") }
end

