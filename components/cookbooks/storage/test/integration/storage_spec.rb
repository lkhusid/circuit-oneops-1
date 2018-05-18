$circuit_path = '/opt/oneops/inductor'
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"
require "#{File.dirname(__FILE__)}/storage_helper"

if $storage_provider_class =~ /azuredatadisk/
  availability_set_response = $storage_provider.availability_sets.get($resource_group_name, $availability_set_name)

  describe 'Azure managed data disks' do
    let (:managed_disks) {$storage_provider.list_managed_disks_by_rg($resource_group_name).select{ |md| (md.os_type.nil?)}}
    it 'are used' do
      expect(managed_disks.size).to be >= $node[:storage][:slice_count].to_i
    end
  end if availability_set_response.sku_name == 'Aligned'

end
