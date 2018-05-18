require 'chef'
require 'fog/azurerm'

Dir.glob('/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azure_base/libraries/*.rb') do |lib|
  require lib
end
require '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azuresecgroup/libraries/network_security_group.rb'

RSpec.configure do |c|
  is_new_cloud = Utils.is_new_cloud($node)
  if is_new_cloud
    c.filter_run_excluding :new_cloud => true
  else
    c.filter_run_excluding :new_cloud => false
  end
end

describe 'Azure Security Group' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
    @nsgclient = AzureNetwork::NetworkSecurityGroup.new(@spec_utils.get_azure_creds)
  end

  context 'Security Group', :new_cloud => true do
    it 'should not exist' do
      @nsgclient = AzureNetwork::NetworkSecurityGroup.new(@spec_utils.get_azure_creds)

      rginfo = @spec_utils.get_resource_group_name
      nsgname = $node['name']

      exists = @nsgclient.check_network_security_group_exists(rginfo, nsgname)
      expect(exists).to eq(false)
    end
  end

  context 'Security Group', :new_cloud => false do
    it 'should exist' do
      rg_location = @spec_utils.get_nsg_rg_location
      rg_name = Utils.get_nsg_rg_name(rg_location)
      sec_rules = @nsgclient.get_sec_rules($node, 'net-sec-group', rg_name)

      all_nsgs_in_rg = @nsgclient.list_security_groups(rg_name)
      matching_nsgs = @nsgclient.get_matching_nsgs(all_nsgs_in_rg, Utils.get_pack_name($node))
      nsg_ID = @nsgclient.match_nsg_rules(matching_nsgs, sec_rules)
      nsg_name = nsg_ID.split('/')[8]

      exists = @nsgclient.check_network_security_group_exists(rg_name, nsg_name)
      expect(exists).to eq(true)
    end
  end
end
