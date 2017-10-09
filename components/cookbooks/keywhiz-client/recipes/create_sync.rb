require 'net/https'
require 'json'

directory '/opt/oneops/keywhiz/keysync/CA' do
  action :create
  recursive true
end

directory '/opt/oneops/keywhiz/keysync/clients' do
  action :create
  recursive true
end

# Make sure to create the directory for tmpfs mount.
directory "#{node.secrets.mount}" do
  action :create
  recursive true
end

# download kw-synch tool and start it with the config file
remote_file '/opt/oneops/keywhiz/keysync/keysync.tar.gz' do
  source node.keywhiz_sync_download_url
  mode '0755'
  action :create
end

# stop the keysync service so that the untar can overwrite the keysync binary
service 'keysync' do
  supports :status => true, :restart => true
  action [:stop]
  only_if {File.exists?('/opt/oneops/keywhiz/keysync/keysync')}
end

execute 'extract_tar' do
  command 'tar --overwrite -xvzf keysync.tar.gz'
  cwd '/opt/oneops/keywhiz/keysync'
  only_if {File.exists?('/opt/oneops/keywhiz/keysync/keysync.tar.gz')}
end

file '/opt/oneops/keywhiz/keysync/clients/client.crt' do
  content node[:cert_content]
end

file '/opt/oneops/keywhiz/keysync/clients/key.encrypted' do
  content node[:key_content]
end

file '/opt/oneops/keywhiz/keysync/CA/cacert.crt' do
  content node[:ca_content]
end

execute "openssl rsa -in /opt/oneops/keywhiz/keysync/clients/key.encrypted -out /opt/oneops/keywhiz/keysync/clients/client.key -passin pass:#{node.sync_cert_passphrase}"

template '/opt/oneops/keywhiz/keysync/config.yaml' do
  source 'keysync-config.erb'
  variables(:user => node.workorder.rfcCi.ciAttributes.user,
            :group => node.workorder.rfcCi.ciAttributes.group,
            :secrets_dir => node.secrets.mount,
            :server => node.keywhiz_service_host + ":" + node.keywhiz_service_port)
end

template '/opt/oneops/keywhiz/keysync/clients/client.yaml' do
  source 'keysync-client.erb'
  variables(:user => node.workorder.rfcCi.ciAttributes.user,
            :group => node.workorder.rfcCi.ciAttributes.group,
            :common_name => node.common_name)
end

# know if this machine runs systemd
runs_systemd = `pidof systemd`
runs_systemd = runs_systemd.chomp.to_i

template '/usr/lib/systemd/system/secrets.mount' do
  source 'secrets.mount.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables(:user => node.workorder.rfcCi.ciAttributes.user,
            :group => node.workorder.rfcCi.ciAttributes.group,
            :secrets_dir => node.secrets.mount)
  only_if {runs_systemd == 1}
end

template '/usr/lib/systemd/system/keysync.service' do
  source 'keysync-service.erb'
  owner 'root'
  group 'root'
  mode 00644
  only_if {runs_systemd == 1}
end

template '/etc/init.d/keysync' do
  source 'keysync-init.erb'
  owner 'root'
  group 'root'
  mode 00755
  variables(:user => node.workorder.rfcCi.ciAttributes.user,
            :group => node.workorder.rfcCi.ciAttributes.group,
            :secrets_dir => node.secrets.mount)
  only_if {runs_systemd != 1}
end

file '/etc/rsyslog.d/oneops-keysync.conf' do
  content ':syslogtag, isequal, "oneops-keysync:" /opt/oneops/log/keysync.log'
end

cookbook_file '/etc/logrotate.d/oneops-keysync' do
  source 'keysync_logrotate'
  action :create
end

execute 'reload_daemon' do
  command 'systemctl daemon-reload'
  only_if {runs_systemd == 1}
end

# Don't try to restart tmpfs mount and make sure to start before keysync.
service 'secrets.mount' do
  action [:enable, :reload, :start]
  only_if {runs_systemd == 1}
end

service 'keysync' do
  supports :status => true, :restart => true
  action [:enable, :reload, :restart]
end

service 'rsyslog' do
  supports :status => true, :restart => true
  action [:enable, :restart]
end

# now check if keysync connected properly

ruby_block 'check_process' do
  block do
    sleep 3
    uri = URI('http://127.0.0.1:31738/metrics')
    metrics_string = Net::HTTP.get(uri) # string
    metrics = JSON.parse(metrics_string)
    metrics.each do |metric|
      if metric['metric'] == 'keysync.seconds_since_last_success'
        metric_value = metric['value']
        Chef::Log.info('Last connected successfully ' + metric_value.to_s + ' seconds ago')
      end
    end
  end
  action :run
end

