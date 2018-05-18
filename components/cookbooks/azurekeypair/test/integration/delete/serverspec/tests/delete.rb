=begin
This spec has tests that validates a successfully completed oneops-azure deployment
=end

COOKBOOKS_PATH ||= "/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require 'chef'
require 'fog/azurerm'
(
Dir.glob("#{COOKBOOKS_PATH}/azure/libraries/*.rb") +
    Dir.glob("#{COOKBOOKS_PATH}/azure_base/libraries/*.rb")
).each {|lib| require lib}

describe "delete Resource Group and availability set on azure" do

  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  context "check resource group" do
    it "can or can't exist in new clouds depending on other resources in same group" do
      rg_svc = AzureBase::ResourceGroupManager.new($node)
      is_new_cloud = rg_svc.is_new_cloud

      if is_new_cloud
        exists = rg_svc.exists?
        if exists
          resources = rg_svc.list_resources
          resource_check = resources.nil? || resources.length == 0
          expect(resource_check).to eq(false)
        end
      elsif
      exists = rg_svc.exists?
        expect(exists).to eq(false)
      end
    end
  end

end