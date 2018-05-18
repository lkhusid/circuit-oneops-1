COOKBOOKS_PATH ||= '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks'.freeze

require 'fog/azurerm'
require "#{COOKBOOKS_PATH}/azuregateway/libraries/application_gateway.rb"
require "#{COOKBOOKS_PATH}/azure_base/libraries/utils.rb"

describe 'azure gateway' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  it 'should exist' do
    application_gateway_service = AzureNetwork::Gateway.new(@spec_utils.get_resource_group_name, @spec_utils.get_application_gateway_name, @spec_utils.get_azure_creds)
    application_gateway = application_gateway_service.get

    expect(application_gateway).not_to be_nil
    expect(application_gateway.name).to eq(@spec_utils.get_application_gateway_name)
  end

  context 'backend address pools' do
    it 'are not empty' do
      application_gateway_service = AzureNetwork::Gateway.new(@spec_utils.get_resource_group_name, @spec_utils.get_application_gateway_name, @spec_utils.get_azure_creds)
      application_gateway = application_gateway_service.get
      ip_address_count = application_gateway.backend_address_pools.first.ip_addresses.count
      vm_count = @spec_utils.get_vm_count

      expect(application_gateway.backend_address_pools).not_to be_nil
      expect(ip_address_count).to eq(vm_count)
    end

    it 'contains private ip addresses of each vm' do
      application_gateway_service = AzureNetwork::Gateway.new(@spec_utils.get_resource_group_name, @spec_utils.get_application_gateway_name, @spec_utils.get_azure_creds)
      application_gateway = application_gateway_service.get
      application_gateway_vm_ip = []
      application_gateway.backend_address_pools.first.ip_addresses.each do |backend_address|
        application_gateway_vm_ip << backend_address.ip_address
      end

      vm_ip_addresses = @spec_utils.get_vm_private_ip_addresses
      vm_ip_addresses.each do |ip_address|
        expect(application_gateway_vm_ip).to include(ip_address)
      end
    end
  end
end
