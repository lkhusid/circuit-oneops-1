COOKBOOKS_PATH ||="/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require 'chef'
require 'fog/azurerm'
(
Dir.glob("#{COOKBOOKS_PATH}/azure/libraries/*.rb") +
    Dir.glob("#{COOKBOOKS_PATH}/azure_base/libraries/*.rb")
).each {|lib| require lib}

#load spec utils
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"

describe "azure vm::delete" do

  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  context "resource group" do
    it "shouldn't exist" do
      rg_svc = AzureBase::ResourceGroupManager.new($node)
      exists = rg_svc.exists?

      expect(exists).to eq(false)
    end
  end

end