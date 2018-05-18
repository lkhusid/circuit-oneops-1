COOKBOOKS_PATH ||= '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks'.freeze

require 'fog/azurerm'
require "#{COOKBOOKS_PATH}/azuregateway/libraries/application_gateway.rb"
require "#{COOKBOOKS_PATH}/azure_base/libraries/utils.rb"

describe 'azure gateway' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  it 'should not exist' do
    application_gateway_service = AzureNetwork::Gateway.new(@spec_utils.get_resource_group_name, @spec_utils.get_application_gateway_name, @spec_utils.get_azure_creds)
    application_gateway = application_gateway_service.exists?

    expect(application_gateway).to eq(false)
  end
end
