=begin
This spec has tests that validates a successfully completed oneops-azure deployment
=end

require 'chef'
require 'fog/azurerm'

Dir.glob('/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azure_base/libraries/*.rb') do |lib|
  require lib
end
require '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azuresecgroup/libraries/network_security_group.rb'
require '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks/azure/libraries/resource_group.rb'

RSpec.configure do |c|
  is_new_cloud = Utils.is_new_cloud($node)
  c.filter_run_excluding :old_cloud => true unless is_new_cloud
end

describe 'Azure Security Group' do
  before(:all) do
    @spec_utils = AzureSpecUtils.new($node)
    @creds = @spec_utils.get_azure_creds
    @nsgclient = AzureNetwork::NetworkSecurityGroup.new(@creds)
    is_new_cloud = Utils.is_new_cloud($node)

    if is_new_cloud
      @rg_location = @spec_utils.get_nsg_rg_location
      @rg_name = Utils.get_nsg_rg_name(@rg_location)
      sec_rules = @nsgclient.get_sec_rules($node, 'net-sec-group', @rg_name)

      all_nsgs_in_rg = @nsgclient.list_security_groups(@rg_name)
      matching_nsgs = @nsgclient.get_matching_nsgs(all_nsgs_in_rg, Utils.get_pack_name($node))
      @nsg_id = @nsgclient.match_nsg_rules(matching_nsgs, sec_rules)
      @nsg_name = @nsg_id.split('/')[8]

    else
      @rg_name =  @spec_utils.get_resource_group_name
      @nsg_name = $node['name']
    end
  end

  context 'NSGs Common Resource Group', :old_cloud => true do
    before :all do
      @rg_manager = AzureBase::ResourceGroupManager.new($node)
      @rg_manager.rg_name = @rg_name
      @resource_group = @rg_manager.get
    end
    it 'should exist' do
      expect(@resource_group).not_to eq(nil)
    end

    it 'should have the correct name of pattern: \'Location_NSGs_RG\'' do
      expect(@resource_group.name).to match(%r{#{@rg_location.upcase}_NSGs_RG})
    end
  end

  context 'Security Group' do
    it 'should exist' do
      nsg = @nsgclient.get(@rg_name, @nsg_name)
      expect(nsg).not_to be_nil
      expect(nsg.name).to eq(@nsg_name)
    end

    it 'should have the correct name of pattern: \'pack_name_nsg_v*\'', :old_cloud => true do
      nsg = @nsgclient.get(@rg_name, @nsg_name)
      expect(nsg.name).to match(%r{#{Utils.get_pack_name($node)}_nsg_v\d})
    end

    it 'should have the right rule count' do
      rulelist = $node['secgroup']['inbound'].tr('"[]\\', '').split(',')
      puts("\t\tLooking for #{rulelist.length} rules in NSG.")

      nsgrules = @nsgclient.list_rules(@rg_name, @nsg_name)

      expect(nsgrules.length).to eq(rulelist.length)
    end

    it 'should set rules correctly' do
      rulelist = $node['secgroup']['inbound'].tr('"[]\\', '').split(',')
      ruleset = @spec_utils.get_azure_rule_definition(@rg_name, @nsg_name, rulelist, $node)


      ruleset.each do |rset|
        puts("\t\tTesting Rule #{rset[:name]}")
        nsgrule = @nsgclient.get_rule(@rg_name, @nsg_name, rset[:name])

        expect(nsgrule).not_to be_nil
        expect(nsgrule.protocol).to eq(rset[:protocol])
        expect(nsgrule.source_port_range).to eq(rset[:source_port_range])
        expect(nsgrule.destination_port_range).to eq(rset[:destination_port_range])
        expect(nsgrule.source_address_prefix).to eq(rset[:source_address_prefix])
        expect(nsgrule.destination_address_prefix).to eq(rset[:destination_address_prefix])
        expect(nsgrule.access).to eq(rset[:access])
        expect(nsgrule.priority).to eq(rset[:priority])
        expect(nsgrule.direction).to eq(rset[:direction])
      end
    end
  end
end