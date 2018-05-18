# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# volume::delete
#
# unmounts, removes: raid, lv vg and detaches blockstorage
#
is_windows = false
is_windows = true if node[:platform] =~ /windows/
has_mounted = false
cloud_name = node[:workorder][:cloud][:ciName]
provider_class = node[:workorder][:services][:compute][cloud_name][:ciClassName].split(".").last.downcase
rfcAttrs = node.workorder.rfcCi.ciAttributes
platform_name = node.workorder.box.ciName
logical_name = node[:workorder][:rfcCi][:ciName]
raid_device = "/dev/md/"+ logical_name
compute_baremetal = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["is_baremetal"]
raid_type = node.workorder.rfcCi.ciAttributes["raid_options"]

Chef::Log.info("Platform_name         : #{platform_name}")
Chef::Log.info("Is platform windows?  : #{is_windows}")
Chef::Log.info("Provider              : #{provider_class}")

unless is_windows
  package 'lvm2'
  package 'mdadm' do
    only_if{::File.exists?(raid_device) || compute_baremetal =~/true/}
  end
end

if rfcAttrs.has_key?("mount_point") && !rfcAttrs["mount_point"].empty?

  mount_point = rfcAttrs["mount_point"].gsub(/\/$/,"")
  Chef::Log.info("umount directory is: #{mount_point}")

  if !is_windows

    out = execute_command("grep #{mount_point} /etc/mtab").stdout
    if !out.empty? && !out.nil?
      has_mounted = true
    end

    package 'lsof' do
      only_if {['centos','redhat','fedora','suse'].include?(node[:platform])}
    end

    ruby_block "killing open files at #{mount_point}" do
      block do
       #1 kill processes that are accesing the mount
       execute_command("lsof #{mount_point} | awk '{print $2}' | grep -v PID | uniq | xargs kill -9")

       #2 remove swap file from the mount
         swap_file = execute_command("cat /proc/swaps | grep #{mount_point} | awk '{print $1}'").stdout.chop
         if !swap_file.nil? && !swap_file.empty?
           execute_command("swapoff #{swap_file}")
         end
      end
      only_if { has_mounted }
    end

    umount_cmd = "umount -Rf #{mount_point}"
    if node['platform_family'] == 'rhel' && node['platform_version'].to_i < 7
      umount_cmd = "umount -f #{mount_point}"
    end
    execute umount_cmd do
      only_if { has_mounted }
    end

    # clear the tmpfs ramdisk entries and/or volume entries from /etc/fstab
    if(rfcAttrs["fstype"] == "tmpfs") || provider_class =~ /azure/ || provider_class =~ /cinder|openstack/
      Chef::Log.info("clearing /etc/fstab entry for fstype tmpfs")
      execute_command("grep -v #{mount_point} /etc/fstab > /tmp/fstab")
      execute_command("mv /tmp/fstab /etc/fstab")
      execute_command("rm -rf '/opt/oneops/azure-restore-ephemeral-mntpts/#{logical_name}.sh'")
      execute_command("cp /etc/rc.local tmpfile;sed -e '/\\/opt\\/oneops\\/azure-restore-ephemeral-mntpts\\/#{logical_name}.sh/d' tmpfile > /etc/rc.local;rm -rf tmpfile")
    end
  else
    ps_volume_script = "#{Chef::Config[:file_cache_path]}/cookbooks/Volume/files/del_disk.ps1"
    cmd = "#{ps_volume_script} \"#{mount_point}\""
    Chef::Log.info("cmd:"+cmd)

    powershell_script "Remove-Windows-Volume" do
      code cmd
    end
  end #if node.platform !~ /windows/
end

ruby_block 'lvremove ephemeral' do
  only_if {::File.exists?("/dev/#{platform_name}-eph/#{logical_name}")}
  not_if {is_windows}
  block do
    execute_command("lvremove -f #{platform_name}-eph/#{logical_name}")
    execute_command("sudo rm -rf #{mount_point}")
  end
end

#Baremetal condition for vgremove, pvremove and mdadm disable
if !compute_baremetal.nil? && compute_baremetal =~/true/
 ruby_block 'baremetal vgremove pvremove ephemeral' do
   block do
     # compute_baremetal = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["is_baremetal"]
     # raid_type = node.workorder.rfcCi.ciAttributes["raid_options"]
     # if !compute_baremetal.nil? && compute_baremetal =~/true/
        if ::File.exists?("/dev/#{platform_name}-eph/#{node.workorder.rfcCi.ciName}")
          Chef::Log.warn("lvremove is not yet completed")
        else
          Chef::Log.info("lvremove is completed")
          #Find out the volume group
          volume_group = Mixlib::ShellOut.new("sudo vgs | grep -v 'VG' | awk '{print $1}'")
          volume_group.run_command
          Chef::Log.warn("#{volume_group.stderr}")
          Chef::Log.info("#{volume_group.stdout}")

          sleep 10
          #vgremove
          Chef::Log.info("Executing vgremove for volume group #{volume_group.stdout}")
          vgremove = Mixlib::ShellOut.new("sudo vgremove -f #{volume_group.stdout}")
          vgremove.run_command
          Chef::Log.info("#{vgremove.stdout}")
          Chef::Log.warn("#{vgremove.stderr}")

          sleep 10

          #Find out physical volume
          physical_volume = Mixlib::ShellOut.new("sudo pvs | awk '{print $1}'| grep -v 'PV' > /var/tmp/pvdevice")
          physical_volume.run_command
          Chef::Log.info("#{physical_volume.stdout}")
          Chef::Log.warn("#{physical_volume.stderr}")

          #pvremove
          Chef::Log.info("Executing pvremove")
          pvremove = Mixlib::ShellOut.new("cat /var/tmp/pvdevice | while read device; do sudo pvremove -f $device; done")
          pvremove.run_command
          Chef::Log.info("#{pvremove.stdout}")
          Chef::Log.warn("#{pvremove.stderr}")

          #mdadm check
          mdadm_check = Mixlib::ShellOut.new("sudo mdadm --detail --scan | grep ARRAY")
          mdadm_check.run_command
          Chef::Log.info("#{mdadm_check.stdout}")
          Chef::Log.warn("#{mdadm_check.stderr}")
          puts "mdadm check exit code:" + "#{mdadm_check.exitstatus}"

          #Proceeding below if RAID1
          if mdadm_check.exitstatus == 0

            #Find out the mdadm device
            mdadm_device = Mixlib::ShellOut.new("sudo mdadm --detail -scan | grep ARRAY | awk '{print $2}'")
            mdadm_device.run_command
            Chef::Log.info("#{mdadm_device.stdout}")
            Chef::Log.warn("#{mdadm_device.stderr}")

            #Stop mdadm
            Chef::Log.info("Stopping mdadm #{mdadm_device.stdout}")
            stop_mdadm = Mixlib::ShellOut.new("sudo mdadm --stop #{mdadm_device.stdout}")
            stop_mdadm.run_command
            Chef::Log.info("#{stop_mdadm.stdout}")
            Chef::Log.warn("#{stop_mdadm.stderr}")

            #zerosupblock mdadm
            Chef::Log.info("Stopping mdadm superblock")
            mdadm_zerosupblock = Mixlib::ShellOut.new("cat /var/tmp/expected_devices | while read device; do sudo mdadm --zero-superblock /dev/$device; done")
            mdadm_zerosupblock.run_command
            Chef::Log.info("#{mdadm_zerosupblock.stdout}")
            Chef::Log.warn("#{mdadm_zerosupblock.stderr}")
            puts "mdadm_zerosupblock exit code:" + "#{mdadm_zerosupblock.exitstatus}"
          end
        end
   end
 end unless is_windows
end

supported = true
if provider_class =~ /virtualbox|vagrant|docker/
  Chef::Log.info(" virtual box vagrant and docker don't support iscsi/ebs via api yet - skipping")
  supported = false
end

storage = nil
storage, device_maps = get_storage(node)

if storage.nil?
  Chef::Log.info("no DependsOn Storage.")
  return
else
  include_recipe "shared::set_provider_new"
  objStorage = VolumeComponent::Storage.new(node,storage,device_maps)
  objStorage.set_provider_data_all
  storage_devices = objStorage.storage_devices
  compute = objStorage.compute
  instance_id = objStorage.instance_id
end

ruby_block 'destroy raid' do
  only_if {::File.exists?(raid_device)}
  not_if {is_windows}
  block do
    max_retry_count = 3
    retry_count = 0

    while retry_count < max_retry_count && ::File.exists?(raid_device) do
      execute_command("mdadm --stop #{raid_device}")
      execute_command("mdadm --remove #{raid_device}")
      retry_count += 1
      if ::File.exists?(raid_device)
        Chef::Log.info("waiting 10sec for raid array to stop/remove")
        sleep 10
      end
    end

    exit_with_error("raid device still exists after many mdadm --stop #{raid_device}") if ::File.exists?(raid_device)
  end
end #ruby_block 'destroy raid' do

ruby_block 'lvremove storage' do
  block do

    if !is_windows
      execute_command("lvremove -f #{platform_name}")
    end #if !is_windows

    storage_devices.each do |storage_device|
      storage_device.detach
    end

  end
end
