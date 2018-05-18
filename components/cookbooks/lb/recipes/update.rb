
env_name = node.workorder.payLoad["Environment"][0]["ciName"]
cloud_name = node.workorder.cloud.ciName

lb_service_type = node.lb.lb_service_type

exit_with_error "#{lb_service_type} service not found. either add it or change service type" if !node.workorder.services.has_key?("#{lb_service_type}")

cloud_service = nil
if !node.workorder.services["#{lb_service_type}"].nil? &&
    !node.workorder.services["#{lb_service_type}"][cloud_name].nil?

  cloud_service = node.workorder.services["#{lb_service_type}"][cloud_name]
end

exit_with_error "no cloud service defined or empty" if cloud_service.nil?

# checking if lb_service_type attribute has changed and initiating migration
config_items_changed= node[:workorder][:rfcCi][:ciBaseAttributes]
old_lb_service_type= config_items_changed[:lb_service_type]

Chef::Log.info("new lb service type value: " +lb_service_type.to_s)
Chef::Log.info("old lb service type value: " +old_lb_service_type.to_s)

if !config_items_changed.empty? && config_items_changed.has_key?("lb_service_type") && config_items_changed[:lb_service_type] != lb_service_type

  #migrate loadbalancer
  include_recipe "lb::migrate"

else
  # Normal loadbalncer update
  case cloud_service[:ciClassName].split(".").last.downcase
  when /octavia/
    include_recipe 'lb::build_load_balancers'
    include_recipe 'octavia::update'
  when /netscaler/
    include_recipe 'lb::add'
  when /azure_lb/
    include_recipe 'lb::add'
  when /azuregateway/
    include_recipe 'lb::add'
  end
end
