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


describe "create Resource Group and availability set on azure" do

  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end


  context "resource group" do
    it "should exist" do

      rg_svc = AzureBase::ResourceGroupManager.new($node)

      exists = rg_svc.exists?

      expect(exists).to eq(true)
    end
  end

  context "availability set" do
    it "should exist" do
      resource_group=@spec_utils.get_resource_group_name
      availability_set = AzureBase::AvailabilitySetManager.new($node)

      avg = availability_set.get
      expect(avg).not_to be_nil
      expect(avg.name).to eq(resource_group)

    end


    it "is Aligned " do

      availability_set = AzureBase::AvailabilitySetManager.new($node)
      avg = availability_set.get
      expect(avg.sku_name).to eq("Aligned")
    end

    it "is Managed" do

      availability_set = AzureBase::AvailabilitySetManager.new($node)
      avg = availability_set.get
      expect(avg.use_managed_disk).to eq(true)

    end

    it "verify update domain" do

      availability_set = AzureBase::AvailabilitySetManager.new($node)
      avg = availability_set.get
      expect(avg.platform_update_domain_count).to eq(Utils.get_update_domains)

    end

    it "verfiy Fault domain" do

      availability_set = AzureBase::AvailabilitySetManager.new($node)
      avg = availability_set.get
      expect(avg.platform_fault_domain_count).to eq(Utils.get_fault_domains(@spec_utils.get_location))

    end

  end

end