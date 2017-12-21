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
    before (:each) do
      traffic_manager_service = TrafficManagers.new(@spec_utils.get_resource_group_name,
                                                    @spec_utils.get_traffic_manager_profile_name,
                                                    @spec_utils.get_azure_creds)

      @traffic_manager_profile = traffic_manager_service.get_profile
    end

    it 'should not exist' do
      expect(@traffic_manager_profile).to be_nil
    end
  end
end
