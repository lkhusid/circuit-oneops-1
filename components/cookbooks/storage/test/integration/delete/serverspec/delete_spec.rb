$circuit_path = '/opt/oneops/inductor'
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"
require "#{File.dirname(__FILE__)}/../../storage_helper"

devices = $node['storage']['device_map'].split(' ')

#Execute provider specific code
volumes_all = $storage_provider.volumes.all if $storage_provider_class =~ /cinder/

#Assert each device from the device_map
devices.each do |dev|
  if $storage_provider_class =~ /azure/ && dev.split(':').size == 5
    #Azure unmanaged disks - old way
    resource_group_name, storage_account_name, ciID, slice_size, dev_id = dev.split(':')
    vol_id = [ciID, 'datadisk',dev.split('/').last.to_s].join('-')
    blob_name = "#{storage_account_name}-#{vol_id}.vhd"
    creds = {
      :tenant_id => $storage_service.instance_variable_get('@tenant_id'),
      :client_id => $storage_service.instance_variable_get('@client_id'),
      :client_secret => $storage_service.instance_variable_get('@client_secret'),
      :subscription_id => $storage_service.instance_variable_get('@subscription_id'),
      :azure_storage_access_key => $storage_service.get_storage_access_keys(resource_group_name, storage_account_name)[1].value,
      :azure_storage_account_name => storage_account_name
    }
    storage_service_new = Fog::Storage::AzureRM.new(creds)

    describe "Blob: #{blob_name}" do
      it 'name has correct format' do
        expect(blob_name).to match(/^\w+-\d+-datadisk-\w+\.vhd$/)
      end

      it 'properties array is empty' do
        expect( storage_service_new.list_blobs('vhds')[:blobs].select{|b| (b.name == blob_name) }).to be_empty
      end
    end

  else
    vol_id = dev.split(':')[0]

    describe "volume name: #{vol_id}" do
      it 'name is not nil' do
        expect(vol_id).not_to be_nil
        expect(vol_id).not_to be_empty
      end
    end

    describe "volume: #{vol_id}" do
      it 'properties array is empty' do
        expect(volumes_all.select{|vol| (vol.id == vol_id) }).to be_empty
      end if $storage_provider_class =~ /cinder/

      it 'managed disk does not exist' do
        expect($storage_provider.managed_disks.check_managed_disk_exists($resource_group_name, vol_id)).to be false
      end if $storage_provider_class =~ /azuredatadisk/

    end
  end
end
