service "zookeeper" do
  provider Chef::Provider::Service::Init
  service_name 'zookeeper'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
  only_if { File.exists?('/etc/init.d/zookeeper') }
end

service "kafka" do
  service_name 'kafka'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
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