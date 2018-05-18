=begin
This spec has tests that validates that the Replace action has run successfully
=end

COOKBOOKS_PATH ||= '/opt/oneops/inductor/circuit-oneops-1/components/cookbooks'

require 'chef'
require 'fog/azurerm'
(
  Dir.glob("#{COOKBOOKS_PATH}/azure/libraries/*.rb") +
  Dir.glob("#{COOKBOOKS_PATH}/azure_base/libraries/*.rb")
).each {|lib| require lib}
#load spec utils
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"

describe 'azure replace' do

  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
    credentials = @spec_utils.get_azure_creds
    virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)
    resource_group_name = @spec_utils.get_resource_group_name
    @server_name = @spec_utils.get_server_name
    @vm = virtual_machine_lib.get(resource_group_name, @server_name)
  end

  context 'virtual machine' do
    it 'should exist' do
      expect(@vm).not_to be_nil
      expect(@vm.name).to eq(@server_name)
    end
  end

  context 'virtual machine os disk' do
    it 'should have proper name' do
      os_disk_name = @spec_utils.get_os_disk_name

      expect(@vm.os_disk_name).not_to be_nil
      expect(@vm.os_disk_name).to eq(os_disk_name)
    end
  end
end
