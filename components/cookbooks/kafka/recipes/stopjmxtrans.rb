service "jmxtrans" do
  provider Chef::Provider::Service::Init
  service_name 'jmxtrans'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end
