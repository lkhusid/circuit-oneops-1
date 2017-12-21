=begin
This spec has tests that validates a successfully completed oneops-azure deployment
=end

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
    it "should exist" do
      nsgclient = AzureNetwork::NetworkSecurityGroup.new(@spec_utils.get_azure_creds)

      rginfo = @spec_utils.get_resource_group_name
      nsgname = $node['name']

      nsg = nsgclient.get(rginfo, nsgname)
      puts(nsg)
      expect(nsg).not_to be_nil
      expect(nsg.name).to eq(nsgname)
    end

    it "should have the right rule count" do
      rulelist = $node['secgroup']['inbound'].tr('"[]\\', '').split(',')
      puts("\t\tLooking for #{rulelist.length} rules in NSG.")      
      nsgclient = AzureNetwork::NetworkSecurityGroup.new(@spec_utils.get_azure_creds)
      rginfo = @spec_utils.get_resource_group_name
      nsgname = $node['name']

      nsgrules = nsgclient.list_rules(rginfo, nsgname)


      expect(nsgrules.length).to eq(rulelist.length)
    end

    it "should set rules correctly" do
      nsgname = $node['name']      
      rginfo = @spec_utils.get_resource_group_name      
      rulelist = $node['secgroup']['inbound'].tr('"[]\\', '').split(',')
      ruleset = @spec_utils.get_azure_rule_definition(rginfo, nsgname, rulelist, $node)

#      puts(ruleset)
    
      nsgclient = AzureNetwork::NetworkSecurityGroup.new(@spec_utils.get_azure_creds)
      
      ruleset.each do |rset|
        puts("\t\tTesting Rule #{rset[:name]}")
        nsgrule = nsgclient.get_rule(rginfo, nsgname, rset[:name])

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