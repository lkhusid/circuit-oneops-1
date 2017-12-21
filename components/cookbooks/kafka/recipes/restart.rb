service "zookeeper" do
  provider Chef::Provider::Service::Systemd
  service_name 'zookeeper'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
  only_if { File.exists?('/etc/init.d/zookeeper') }
end

service "kafka" do
  provider Chef::Provider::Service::Systemd
  service_name 'kafka'
  supports  :stop => true, :status => true, :stop => true, :start => true
  action :stop
end

sleep 30

service "kafka" do
  provider Chef::Provider::Service::Systemd
  service_name 'kafka'
  supports  :start => true, :status => true, :stop => true, :start => true
  action :start
end

ruby_block "kafka_running" do
    Chef::Resource::RubyBlock.send(:include, Kafka::StartUtil)
    block do
        if !kafka_running
            puts "***FAULT:FATAL=Kafka isn't running"
            e = Exception.new("no backtrace")
            e.set_backtrace("")
            raise e
        end
        ensureBrokerIDInZK
    end
end