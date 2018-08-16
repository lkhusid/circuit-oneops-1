`mkdir -p /var/run/jmxtrans && chown jmxtrans:jmxtrans /var/run/jmxtrans`

service "jmxtrans" do
  provider Chef::Provider::Service::Init
  service_name 'jmxtrans'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :start
end