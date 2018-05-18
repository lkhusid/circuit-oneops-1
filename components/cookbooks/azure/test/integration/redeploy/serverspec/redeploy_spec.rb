COOKBOOKS_PATH ||= "/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require "/opt/oneops/inductor/circuit-oneops-1/components/spec_helper.rb"
require 'chef'
require 'fog/azurerm'
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"
(
Dir.glob("#{COOKBOOKS_PATH}/azure/libraries/*.rb") +
    Dir.glob("#{COOKBOOKS_PATH}/azure_base/libraries/*.rb")
).each {|lib| require lib}

#run the add specs to make sure that the compute's config stays same after redeploy
add_specs = File.expand_path("#{COOKBOOKS_PATH}/azure/test/integration/add/serverspec/tests", File.dirname(__FILE__))
Dir.glob("#{add_specs}/*.rb").each {|tst| require tst}

describe 'azure compute::redeploy' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  it 'fault domian and update domain should stay same' do
    vm_name = $node['workorder']['rfcCi']['ciAttributes']['instance_name']

    #this is the info before vm is redeployed.
    zone_from_wo = JSON.parse($node['workorder']['rfcCi']['ciAttributes']['zone'])
    fd_from_wo = zone_from_wo['fault_domain'].to_i
    ud_from_wo = zone_from_wo['update_domain'].to_i

    #get the compute info from azure and compare its config with data in wo.
    vm_svc = AzureCompute::VirtualMachine.new(@spec_utils.get_azure_creds)
    vm = vm_svc.get(@spec_utils.get_resource_group_name, vm_name)

    expect(vm.platform_fault_domain.to_i).to eq(fd_from_wo)
    expect(vm.platform_update_domain.to_i).to eq(ud_from_wo)
  end

  it 'ip stays same' do

    rg_name = @spec_utils.get_resource_group_name
    azure_creds = @spec_utils.get_azure_creds
    vm_name = $node['workorder']['rfcCi']['ciAttributes']['instance_name']
    vm_svc = AzureCompute::VirtualMachine.new(azure_creds)
    vm = vm_svc.get(rg_name, vm_name)

    nic_svc = AzureNetwork::NetworkInterfaceCard.new(azure_creds)
    nic_svc.rg_name = rg_name
    nic_name = nic_svc.get_nic_name(vm.network_interface_card_ids[0])
    nic = nic_svc.get(nic_name)

    private_ip_from_wo = $node['workorder']['rfcCi']['ciAttributes']['private_ip']
    pubic_ip_from_wo = $node['workorder']['rfcCi']['ciAttributes']['public_ip']

    if @spec_utils.is_express_route_enabled
      expect(nic.private_ip_address).to eq(private_ip_from_wo)
    else
      public_ip_svc = AzureNetwork::PublicIp.new(azure_creds)
      public_ip_name = nic.public_ip_address_id.split('/').last
      public_ip_obj = public_ip_svc.get(rg_name, public_ip_name)

      expect(public_ip_obj.ip_address).to eq(pubic_ip_from_wo)
    end
  end
end

