require 'azure_mgmt_network'
require '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azure_base/test/integration/azure_spec_utils'

class AzureLBSpecUtils < AzureSpecUtils
  def get_lb_name
    platform_name = @node['workorder']['box']['ciName']
    plat_name = platform_name.gsub(/-/, '').downcase
    lb_name = "lb-#{plat_name}"

    lb_name
  end
  def get_probes
    probes = []
    ecvs = AzureNetwork::LoadBalancer.get_probes_from_wo(@node)

    ecvs.each do |ecv|
      probe = AzureNetwork::LoadBalancer.create_probe(ecv[:probe_name], ecv[:protocol], ecv[:port], ecv[:interval_secs], ecv[:num_probes], ecv[:request_path])
      probes.push(probe)
    end
    probes
  end
  def get_loadbalancer_rules(subscription_id, resource_group_name, lb_name, env_name, platform_name, probes, frontend_ipconfig_id, backend_address_pool_id)
    lb_rules = []

    ci = {}
    ci = @node.workorder.key?('rfcCi') ? @node.workorder.rfcCi : @node.workorder.ci

    listeners = AzureNetwork::LoadBalancer.get_listeners(@node)

    listeners.each do |listener|
      lb_rule_name = "#{env_name}.#{platform_name}-#{listener[:vport]}_#{listener[:iport]}tcp-#{ci[:ciId]}-lbrule"
      frontend_port = listener[:vport]
      backend_port = listener[:iport]
      protocol = 'Tcp'
      load_distribution = 'Default'

      ### Select the right probe for the lb rule
      the_probe = AzureNetwork::LoadBalancer.get_probe_for_listener(listener, probes)
      if(the_probe.nil?)
        OOLog.fatal("No valid ecv specified for listener: #{listener[:vprotocol]} #{listener[:vport]} #{listener[:iprotocol]} #{listener[:iport]}")
      end

      probe_id = "/subscriptions/#{subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/loadBalancers/#{lb_name}/probes/#{the_probe[:name]}"
      lb_rule = AzureNetwork::LoadBalancer.create_lb_rule(lb_rule_name, load_distribution, protocol, frontend_port, backend_port, probe_id, frontend_ipconfig_id, backend_address_pool_id)
      lb_rules.push(lb_rule)
    end

    lb_rules
  end

  # Returns backend ip configurations of a load balancer
  # == Parameters:
  # resource_group_name::
  #   Name of the resource group the load balancer belongs to
  # lb_name::
  #   Name of the load balancer
  # backend_address_pool_id::
  #   A load balancer can have more than one backend address pool
  #   If this is `nil`,`backend_ipconfigurations` of first `backend_address_pool` is returned
  #   If it is not `nil`, `backend_ipconfigurations` of the specified `backend_address_pool` is returned
  #   When it is not nil, provide backend address pool id in format - `/subscriptions/{subscription id}/resourceGroups/{resource group name}/providers/Microsoft.Network/loadBalancers/{load balancer name}/backendAddressPools/{backend address pool name}`
  #
  # == Returns:
  # Array of objects. Each object has an `id` property which specifies the `id` of network interface ip configuration
  # This `id` is in the format `/subscriptions/{subscription id}/resourceGroups/{resource group name}/providers/Microsoft.Network/networkInterfaces/{nic name}/ipConfigurations/{nic ip config name}`
  def get_backend_ip_configurations(resource_group_name, lb_name, backend_address_pool_id = nil)

    creds = get_azure_creds
    token_provider                  = MsRestAzure::ApplicationTokenProvider.new(creds[:tenant_id], creds[:client_id], creds[:client_secret])
    credentials                     = MsRest::TokenCredentials.new(token_provider)
    network_client                  = Azure::ARM::Network::NetworkManagementClient.new(credentials)
    network_client.subscription_id  = creds[:subscription_id]


    lb = network_client.load_balancers.get(resource_group_name, lb_name, nil, nil)
    backend_ip_configurations = nil

    if backend_address_pool_id.nil?
      backend_ip_configurations = lb.backend_address_pools[0].backend_ipconfigurations
    else
      backend_address_pool = lb.backend_address_pools.detect {|p| p.id == backend_address_pool_id}
      backend_ip_configurations = backend_address_pool.backend_ipconfigurations unless backend_address_pool.nil?
    end

    return backend_ip_configurations
  end
end