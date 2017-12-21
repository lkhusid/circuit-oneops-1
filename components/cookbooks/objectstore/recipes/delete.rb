file '/etc/objectstore_creds.json' do
  mode '0600'
  action :delete
end

file '/usr/local/bin/objectstore' do
  mode '0600'
  action :delete
end
