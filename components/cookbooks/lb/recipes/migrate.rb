Chef::Log.info("Migrating loadbalancer")

# Creating new loadbalancer
Chef::Log.info("Creating New loadbalancer")
include_recipe "lb::add"

# If creation is success , delete old loadbalancer
cloud_name = node.workorder.cloud.ciName

# Fetching old configuration
old_lb_service_type = node[:workorder][:rfcCi][:ciBaseAttributes][:lb_service_type]
old_cloud_service = nil
if !node.workorder.services["#{old_lb_service_type}"].nil? &&
    !node.workorder.services["#{old_lb_service_type}"][cloud_name].nil?

  old_cloud_service = node.workorder.services["#{old_lb_service_type}"][cloud_name]
end
exit_with_error "Not able to find cloud service with servicetype: #{old_lb_service_type}" if old_cloud_service.nil?
Chef::Log.info("Deleting existing loadbalancer with servicetype: #{old_lb_service_type}")

# Deleting old loadbalancer
include_recipe "lb::build_load_balancers"

case old_cloud_service[:ciClassName].split(".").last.downcase
  when /azure_lb/

    include_recipe "azure_lb::delete"

  when /netscaler/

    n = netscaler_connection "conn" do
      action :nothing
    end
    n.run_action(:create)

    include_recipe "netscaler::delete_lbvserver"
    include_recipe "netscaler::delete_servicegroup"
    include_recipe "netscaler::delete_server"
    include_recipe "netscaler::logout"

  when /octavia/
    include_recipe "octavia::delete_lb"
end
