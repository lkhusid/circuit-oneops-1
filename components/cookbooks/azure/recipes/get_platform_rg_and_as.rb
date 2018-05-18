# a little recipe that sets the platform, platform-resource-group and platform-availability-set for azure deployments.
# several other recipes use this
require 'fog/azurerm'
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)
require File.expand_path('../../../azure_base/libraries/utils.rb', __FILE__)


OOLog.info('get_platform_rg_and_as.rb called from')
OOLog.info(node.run_list[0])

node.run_list.each do |recipe|
  if recipe == 'recipe[compute::status]' || recipe == 'recipe[compute::reboot]' || recipe == 'recipe[compute::powercycle]'
    ci = node['workorder']['ci']
    cloud_name = node['workorder']['cloud']['ciName']
    OOLog.info('cloud_name is: ' + cloud_name)
    compute_service = node['workorder']['services']['compute'][cloud_name]['ciAttributes']
    OOLog.debug("ci attrs: #{ci['ciAttributes'].inspect.gsub('\n',' ')}")

    metadata = ci['ciAttributes']['metadata']
    node.set['vm_name'] = ci['ciAttributes']['instance_name']
    metadata_obj= JSON.parse(metadata)
    org = metadata_obj['organization']
    assembly = metadata_obj['assembly']
    platform = metadata_obj['platform']
    env = metadata_obj['environment']
    location = compute_service['location']
    node.set['subscriptionid'] = compute_service['subscription']
    resource_group_name = generate_rg_name(org,assembly,platform,env,location)
    node.set['platform-resource-group'] = resource_group_name
    return true
  end
end

app_type = node['app_name']

cloud_name = node['workorder']['cloud']['ciName']

location = case app_type
             when 'lb'
               node['workorder']['services']['lb'][cloud_name][:ciAttributes][:location]
             when 'fqdn'
               node['workorder']['services']['dns'][cloud_name][:ciAttributes][:location]
             when 'storage'
               node['workorder']['services']['storage'][cloud_name][:ciAttributes][:region]
             else
               node['workorder']['services']['compute'][cloud_name][:ciAttributes][:location]
           end

OOLog.fatal('Azure location/region not found') if location.nil?

keypair = node['workorder']['rfcCi']
nsPathParts = keypair['nsPath'].split('/')

platform = nsPathParts[5]


rg_manager = AzureBase::ResourceGroupManager.new(node)
as_manager = AzureBase::AvailabilitySetManager.new(node)


node.set['platform-resource-group'] = rg_manager.rg_name
node.set['platform-availability-set'] = as_manager.as_name
node.set['platform'] = platform
