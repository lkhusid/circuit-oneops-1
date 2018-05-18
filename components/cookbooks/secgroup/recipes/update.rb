#
# Cookbook Name:: secgroup
# Recipe:: update
#
cloud_name = node['workorder']['cloud']['ciName']
provider = node[:workorder][:services][:compute][cloud_name][:ciClassName].downcase

is_new_cloud = Utils.is_new_cloud(node)

if provider =~ /azure/ && is_new_cloud
  include_recipe 'azuresecgroup::update_secgroup'
else
  include_recipe 'secgroup::add'
end

