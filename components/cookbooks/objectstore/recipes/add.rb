cloud_name = node[:workorder][:cloud][:ciName]
cloud_type = node[:workorder][:services][:filestore][cloud_name][:ciClassName].split('.').last.downcase
ciAttr = node[:workorder][:services][:filestore][cloud_name][:ciAttributes]

case cloud_type
when /swift/
  creds = {
    :provider           => 'OpenStack',
    :openstack_api_key  => ciAttr[:password],
    :openstack_username => ciAttr[:username],
    :openstack_tenant   => ciAttr[:tenant],
    :openstack_auth_url => ciAttr[:endpoint] + '/tokens',
    :openstack_region   => ciAttr[:regionname]
  }
when /azureobjectstore/
  creds = {
    :provider                   => 'Azure',
    :azure_storage_account_name => ciAttr[:storage_account_name],
    :azure_storage_access_key   => ciAttr[:storage_account_access_key]
  }
end

require 'json'
file '/etc/objectstore_creds.json' do
  content creds.to_json
end

cookbook_file 'objectstore' do
  mode '0755'
  path '/usr/local/bin/objectstore'
end

execute 'fix_dependency' do
  command 'gem uninstall fog-profitbricks -v 2.0.1 ; true'
  action :run
end
