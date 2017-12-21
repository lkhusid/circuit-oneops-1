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

  context "delete resource group" do
    it "should not exist" do

      rg_svc = AzureBase::ResourceGroupManager.new($node)

      exists = rg_svc.exists?

      expect(exists).to eq(false)
    end
  end

end