require 'chef'
require 'fog/azurerm'

Dir.glob('/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azure_base/libraries/*.rb') do |lib|
  require lib
end
require "/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azuresecgroup/libraries/network_security_group.rb"

describe "Azure Security Group" do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
  end

  context "Security Group" do
    it "should not exist" do
      nsgclient = AzureNetwork::NetworkSecurityGroup.new(@spec_utils.get_azure_creds)

      rginfo = @spec_utils.get_resource_group_name
      nsgname = $node['name']

      nsg = nsgclient.get(rginfo, nsgname)
      expect(nsg).to be_nil
    end
  end
end