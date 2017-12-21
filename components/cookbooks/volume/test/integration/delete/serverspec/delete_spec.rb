is_windows = ENV['OS']=='Windows_NT' ? true : false
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"
require "#{$circuit_path}/circuit-oneops-1/components/cookbooks/volume/test/integration/volume_helper.rb"

describe file($mount_point) do
 it { should_not be_mounted }
end unless is_windows #TO-DO Check with Powershell directly, if the $mount_point is actually mounted and set online

#assert each storage device from the map - a service file needs to exist in /opt/oneops/storage_devices
$device_map.each do |dev|
  if dev.split(':').size > 2
    resource_group_name, storage_account_name, ciID, slice_size, dev_id = dev.split(':')
    vol_id = [ciID, 'datadisk',dev.split('/').last.to_s].join('-')
  else
    vol_id, dev_id = dev.split(":")
  end

  reg = Regexp.new( "^#{Regexp.escape(dev_id)}:$" )

  describe file("/opt/oneops/storage_devices/#{vol_id}") do
    it { should be_file }
    its(:content) {should match reg}
  end

end if $storage && !is_windows #TO-DO start using the service files for windows as well, then we can enable these tests
