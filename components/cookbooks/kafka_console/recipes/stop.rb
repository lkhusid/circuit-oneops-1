service "kafka-manager" do
  provider Chef::Provider::Service::Init
  service_name 'kafka-manager'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end

#service 'burrow' do
 # service_name 'burrow'
 # supports  :restart => true, :status => true, :stop => true, :start => true
 # action :stop
#end
