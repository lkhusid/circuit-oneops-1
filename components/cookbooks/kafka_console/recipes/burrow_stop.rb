service 'burrow' do
  service_name 'burrow'
  supports  :restart => true, :status => true, :stop => true, :start => true
  action :stop
end
