#########################################################################
#
# Test: Validate successful deployment Azure Traffic Manager by OneOps
#
#########################################################################

COOKBOOKS_PATH ||= '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks'.freeze

require 'chef'
require 'fog/azurerm'

(
  Dir.glob("#{COOKBOOKS_PATH}/azure/libraries/*.rb") +
  Dir.glob("#{COOKBOOKS_PATH}/azure_base/libraries/*.rb")
).each { |lib| require lib }

require "#{COOKBOOKS_PATH}/azuretrafficmanager/libraries/traffic_managers.rb"

describe 'traffic manager on azure' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  context 'traffic manager profile' do
    before(:each) do
      traffic_manager_service = TrafficManagers.new(@spec_utils.get_resource_group_name,
                                                    @spec_utils.get_traffic_manager_profile_name,
                                                    @spec_utils.get_azure_creds)

      @traffic_manager_profile = traffic_manager_service.get_profile
    end

    it 'should exist' do
      expect(@traffic_manager_profile).not_to be_nil
    end

    it 'should be enabled' do
      expect(@traffic_manager_profile.profile_status).to eq('Enabled')
    end

    it 'should have correct name' do
      expect(@traffic_manager_profile.name).to eq(@spec_utils.get_traffic_manager_profile_name)
    end

    it 'should have correct routing method' do
      traffic_routing_method = @spec_utils.get_traffic_manager_routing_method
      expect(@traffic_manager_profile.traffic_routing_method).to eq(traffic_routing_method)
    end

    it 'should have correct TTL' do
      traffic_manager_ttl = @spec_utils.get_traffic_manager_ttl.to_i
      expect(@traffic_manager_profile.ttl).to eq(traffic_manager_ttl)
    end
  end

  context 'traffic manager endpoints' do
    before(:each) do
      resource_group_name = @spec_utils.get_resource_group_name
      traffic_manager_profile_name = @spec_utils.get_traffic_manager_profile_name
      azure_credentials = @spec_utils.get_azure_creds

      traffic_manager_service = TrafficManagers.new(resource_group_name,
                                                    traffic_manager_profile_name,
                                                    azure_credentials)

      @traffic_manager_profile = traffic_manager_service.get_profile
    end

    it 'should exist' do
      endpoints = @traffic_manager_profile.endpoints
      expect(endpoints).not_to be_nil
    end

    it 'should be enabled' do
      endpoint_status = @traffic_manager_profile.endpoints[0].endpoint_status
      expect(endpoint_status).to eq('Enabled')
    end
  end
end
