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

  context 'virtual machine' do
    it 'should not exist' do
      credentials = @spec_utils.get_azure_creds
      virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)

      resource_group_name = @spec_utils.get_resource_group_name
      server_name = @spec_utils.get_server_name
      exists = virtual_machine_lib.check_vm_exists?(resource_group_name, server_name)

      expect(exists).to eq(false)
    end
  end

end