$circuit_path = '/opt/oneops/inductor'
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"
require "#{File.dirname(__FILE__)}/storage_helper"

if $storage_provider_class =~ /azuredatadisk/
  managed_disks = $storage_provider.list_managed_disks_by_rg($resource_group_name).select{ |md| (md.os_type.nil?)}

  describe 'Azure managed data disks' do
    it 'are used' do
      expect(managed_disks.size).to be >= $node[:storage][:slice_count].to_i
    end
  end
end
