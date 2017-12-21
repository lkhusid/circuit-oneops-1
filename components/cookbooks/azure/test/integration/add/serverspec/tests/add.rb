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
require "#{COOKBOOKS_PATH}/azuresecgroup/libraries/network_security_group.rb"

#load spec utils
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"

RSpec.configure do |c|
  c.filter_run_excluding :express_route_enabled => !AzureSpecUtils.new($node).is_express_route_enabled
end

RSpec.configure do |c|
  c.filter_run_excluding :custom_image => AzureSpecUtils.new($node).is_imagetypecustom
end

describe "azure node::create" do

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

  context "vm" do
    it "should exist" do
      credentials = @spec_utils.get_azure_creds
      virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)

      resource_group_name = @spec_utils.get_resource_group_name
      server_name = @spec_utils.get_server_name
      vm = virtual_machine_lib.get(resource_group_name, server_name)

      expect(vm).not_to be_nil
      expect(vm.name).to eq(server_name)
    end

    it "should created from custom image" , :custom_image  => true do

    credentials = @spec_utils.get_azure_creds
    virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)

    resource_group_name = @spec_utils.get_resource_group_name
    server_name = @spec_utils.get_server_name
    vm = virtual_machine_lib.get(resource_group_name, server_name)

    expect(vm.publisher).to be_nil

    end


    context "compute size" do
      it "should exist" do
        credentials = @spec_utils.get_azure_creds
        virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)

        resource_group_name = @spec_utils.get_resource_group_name
        server_name = @spec_utils.get_server_name
        vm = virtual_machine_lib.get(resource_group_name, server_name)

        availability_set = AzureBase::AvailabilitySetManager.new($node)
        avg = availability_set.get

        if avg.sku_name.eql? 'Classic'
          storage_profile = AzureCompute::StorageProfile.new(credentials)
          expect(vm.vm_size).to eq(storage_profile.get_old_azure_mapping($node[:workorder][:rfcCi][:ciAttributes][:size]))
        elsif if avg.sku_name.eql? 'Aligned'

                cloud_name = $node[:workorder][:cloud][:ciName]
                cloud = $node[:workorder][:services][:compute][cloud_name][:ciAttributes]

                sizemap = JSON.parse(cloud[:sizemap])
                size_id = sizemap[$node[:workorder][:rfcCi]["ciAttributes"]["size"]]

                expect(vm.vm_size).to eq(size_id)
              end
        end
      end
    end

    context "instance type" , :custom_image  => false do
      it "should exist" do
        credentials = @spec_utils.get_azure_creds
        virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)

        resource_group_name = @spec_utils.get_resource_group_name
        server_name = @spec_utils.get_server_name
        vm = virtual_machine_lib.get(resource_group_name, server_name)
        compute_instance = (vm.offer + "-" + vm.sku.to_s).downcase
        expect(compute_instance).to eq($node[:workorder][:payLoad][:os][0][:ciAttributes]['ostype'].downcase)
      end
    end

     it "has oneops org and assembly tags" do
      tags_from_work_order = Utils.get_resource_tags($node)

      credentials = @spec_utils.get_azure_creds
      virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)
      vm = virtual_machine_lib.get(@spec_utils.get_resource_group_name, @spec_utils.get_server_name)

      tags_from_work_order.each do |key, value|
        expect(vm.tags).to include(key => value)
      end
    end
  end

  context "Fault and Update domain" do
    it "Fault and Update domain returns" do

      credentials = @spec_utils.get_azure_creds
      virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)
      resource_group_name = @spec_utils.get_resource_group_name
      server_name = @spec_utils.get_server_name
      vm = virtual_machine_lib.get(resource_group_name, server_name)
      expect(vm.platform_fault_domain).not_to be_nil
      expect(vm.platform_update_domain).not_to be_nil
    end
  end

  context "os disk" do
    it "should exist" do
      credentials = @spec_utils.get_azure_creds
      virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)
      vm = virtual_machine_lib.get(@spec_utils.get_resource_group_name, @spec_utils.get_server_name)

      expect(vm.os_disk_name).not_to be_nil
      expect(vm.os_disk_name).not_to eq('')

      azure_compute_service = Fog::Compute::AzureRM.new(credentials)
      os_disk = azure_compute_service
                    .managed_disks
                    .get(@spec_utils.get_resource_group_name, vm.os_disk_name)


      expect(os_disk).not_to be_nil
      expect(os_disk.provisioning_state).to eq('Succeeded')
    end

    it 'is managed' do
      credentials = @spec_utils.get_azure_creds
      virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)
      vm = virtual_machine_lib.get(@spec_utils.get_resource_group_name, @spec_utils.get_server_name)

      azure_compute_service = Fog::Compute::AzureRM.new(credentials)
      os_disk = azure_compute_service
                    .managed_disks
                    .get(@spec_utils.get_resource_group_name, vm.os_disk_name)

      expect(vm.storage_account_name).to be_nil
      expect(os_disk).to be_a_kind_of(Fog::Compute::AzureRM::ManagedDisk)
      expect(os_disk.creation_data.storage_account_id).to be_nil
    end

    it "has oneops org and assembly tags" do
      tags_from_work_order = Utils.get_resource_tags($node)

      credentials = @spec_utils.get_azure_creds
      virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)
      vm = virtual_machine_lib.get(@spec_utils.get_resource_group_name, @spec_utils.get_server_name)

      azure_compute_service = Fog::Compute::AzureRM.new(credentials)
      os_disk = azure_compute_service
                    .managed_disks
                    .get(@spec_utils.get_resource_group_name, vm.os_disk_name)

      tags_from_work_order.each do |key, value|
        expect(os_disk.tags).to include(key => value)
      end
    end
  end

  context "nic" do
    it "uses predefined virtual network when express route is enabled", :express_route_enabled => true do

      @spec_utils.set_attributes_on_node_required_for_vm_manager
      vm_manager = AzureCompute::VirtualMachineManager.new($node)
      predefined_vnet = vm_manager.compute_service['network']

      credentials = @spec_utils.get_azure_creds
      virtual_machine_lib = AzureCompute::VirtualMachine.new(credentials)
      vm = virtual_machine_lib.get(@spec_utils.get_resource_group_name, @spec_utils.get_server_name)
      primary_nic_id = vm.network_interface_card_ids[0]
      primary_nic_name = Hash[*(primary_nic_id.split('/'))[1..-1]]['networkInterfaces']

      nic_svc = AzureNetwork::NetworkInterfaceCard.new(credentials)
      nic_svc.rg_name = @spec_utils.get_resource_group_name
      nic = nic_svc.get(primary_nic_name)

      nic_subnet_vnet = Hash[*(nic.subnet_id.split('/'))[1..-1]]['virtualNetworks']
      expect(nic_subnet_vnet).to eq(predefined_vnet)
    end

    it "has oneops org and assembly tags" do
      tags_from_work_order = Utils.get_resource_tags($node)

      nic_svc = AzureNetwork::NetworkInterfaceCard.new(@spec_utils.get_azure_creds)
      nic_svc.ci_id = $node['workorder']['rfcCi']['ciId']
      nic_svc.rg_name = @spec_utils.get_resource_group_name
      nic_name = Utils.get_component_name('nic', nic_svc.ci_id)
      nic = nic_svc.get(nic_name)

      tags_from_work_order.each do |key, value|
        expect(nic.tags).to include(key => value)
      end

    end
  end

end