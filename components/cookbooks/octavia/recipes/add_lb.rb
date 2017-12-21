require File.expand_path('../../libraries/models/lbaas/loadbalancer_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/listener_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/pool_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/member_model', __FILE__)
require File.expand_path('../../libraries/models/lbaas/health_monitor_model', __FILE__)
require File.expand_path('../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../libraries/loadbalancer_manager', __FILE__)
require File.expand_path('../../libraries/network_manager', __FILE__)
require File.expand_path('../../libraries/utils', __FILE__)
require File.expand_path('../../../barbican/libraries/barbican_utils', __FILE__)
require File.expand_path('../../../barbican/libraries/secret_manager', __FILE__)
#-------------------------------------------------------
lb_attributes = node[:workorder][:rfcCi][:ciAttributes]
cloud_name = node[:workorder][:cloud][:ciName]
service_lb_attributes = node[:workorder][:services][:slb][cloud_name][:ciAttributes]
tenant = TenantModel.new(service_lb_attributes[:endpoint],service_lb_attributes[:tenant],
                         service_lb_attributes[:username],service_lb_attributes[:password])
stickiness = lb_attributes[:stickiness]
persistence_type = lb_attributes[:persistence_type]
Chef::Log.info("enabled networks: #{service_lb_attributes[:enabled_networks]} ")

subnet_id = select_provider_network_to_use(tenant, service_lb_attributes[:enabled_networks])

barbican_container_name = get_barbican_container_name()
connection_limit = (lb_attributes[:connection_limit]).to_i
Chef::Log.info("connection_limit : #{connection_limit}")

include_recipe "octavia::build_lb_name"
lb_name = node[:lb_name]
listeners = Array.new
#loadbalancers array contains a list of listeners from lb::build_load_balancers
node.loadbalancers.each do |loadbalancer|
  vprotocol = loadbalancer[:vprotocol]
  vport = loadbalancer[:vport]
  iprotocol = loadbalancer[:iprotocol]
  iport = loadbalancer[:iport]
  sg_name = loadbalancer[:sg_name]

  if vprotocol == "SSL"
    vprotocol = "HTTPS"
  end

  if iprotocol == "SSL"
    iprotocol = "HTTPS"
  end

  if (vprotocol == 'HTTP' and iprotocol == 'HTTPS')
    Chef::Log.error(loadbalancer)
    Chef::Log.error('Protocol Mismatch in listener config')
    raise Exception, 'Protocol Mismatch in listener config'
  end

  members = initialize_members(subnet_id, iport)

  if (iprotocol == 'SSL_BRIDGE' || iprotocol == 'TCP')
    health_monitor = initialize_health_monitor('TCP', lb_attributes[:ecv_map], lb_name, iport)
    pool = initialize_pool('TCP', iport, lb_attributes[:lbmethod], lb_name, members, health_monitor, stickiness, persistence_type)
  else
    health_monitor = initialize_health_monitor(iprotocol, lb_attributes[:ecv_map], lb_name, iport)
    pool = initialize_pool(iprotocol, iport, lb_attributes[:lbmethod], lb_name, members, health_monitor, stickiness, persistence_type)
  end

  if (vprotocol == 'TERMINATED_HTTPS' || vprotocol == 'HTTPS')
    if !barbican_container_name.nil? && !barbican_container_name.empty?
      secret_manager = SecretManager.new(service_lb_attributes[:endpoint], service_lb_attributes[:username],service_lb_attributes[:password], service_lb_attributes[:tenant] )
      container_ref = secret_manager.get_container(barbican_container_name)
      Chef::Log.info("Container_ref : #{container_ref}")
      if !container_ref
        Chef::Log.error("Unable to fetch Barbican container href for container name : #{barbican_container_name}")
        raise Exception, "Unable to fetch Barbican container href for container name : #{barbican_container_name}"
      end
      if iprotocol == 'HTTP'
        listeners.push(initialize_listener("TERMINATED_HTTPS", vport, lb_name, pool, connection_limit, container_ref))
      elsif iprotocol == 'HTTPS'
        listeners.push(initialize_listener("HTTPS", vport, lb_name, pool, connection_limit))
      end
    else
      Chef::Log.error('Barbican cert container not found for HTTPS type protocol')
      raise Exception, 'Barbican cert container not found for HTTPS type protocol'
    end
  elsif (vprotocol == 'SSL_BRIDGE' || vprotocol == 'TCP')
    listeners.push(initialize_listener("TCP", vport, lb_name, pool, connection_limit))
  else
    listeners.push(initialize_listener(vprotocol, vport, lb_name, pool, connection_limit))
  end

end
loadbalancer = initialize_loadbalancer(subnet_id, service_lb_attributes[:provider], lb_name, listeners)

lb_manager = LoadbalancerManager.new(tenant)
Chef::Log.info("Creating Loadbalancer ..." + lb_name)
start_time = Time.now
Chef::Log.info("start time " + start_time.to_s)
loadbalancer_id = lb_manager.create_loadbalancer(loadbalancer)
Chef::Log.info("end time " + Time.now.to_s)
total_time = Time.now - start_time
Chef::Log.info("Total time to create " + total_time.to_s)

lb = lb_manager.get_loadbalancer(loadbalancer_id)
node.set[:lb_dns_name] = lb.vip_address
Chef::Log.info("VIP Address: " + lb.vip_address.to_s)

vnames = get_dc_lb_names()
vnames[lb_name] = nil
vnames.keys.each do |key|
  vnames[key] = lb.vip_address
end

Chef::Log.info("Exiting octavia-lbaas add recipe.")

puts "***RESULT:vnames=" + vnames.to_json
