`mkdir -p /var/run/jmxtrans && chown jmxtrans:jmxtrans /var/run/jmxtrans`

service "jmxtrans" do
  service_name 'jmxtrans'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :restart
end