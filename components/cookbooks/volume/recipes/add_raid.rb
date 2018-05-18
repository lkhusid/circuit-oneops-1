# This recipe works only for Openstack baremetal service
Chef::Log.info('RAID volume add recipe')

# Install lsscsi package for non-windows platform
if node.platform =~ /windows/
  include_recipe "volume::windows_vol_add"
  return
else
  package "lsscsi"
end

#List the devices available on baremetal node
bash "execute_RAID" do
  code <<-EOH
     /usr/bin/lsscsi | grep -v `df -h |grep sd | awk -F\/ '{print $3}' | awk '{print $1}' | cut -c1-3` | grep "/dev/sd" | sed 's#.*/dev/\\(sd[[:alnum:]]\\).*#\\1#g' | sort | uniq > /var/tmp/expected_devices
  EOH
end

storage = nil
storage,device_maps = get_storage(node)

if !storage.nil?
  exit_with_error("Block storage is not supported with baremetal")
end

include_recipe "shared::set_provider"

if node[:provider_class] != 'openstack'
  exit_with_error("Baremetal is only supported for Openstack")
end

size = node.workorder.rfcCi.ciAttributes["size"].gsub(/\s+/, "")

package "lvm2"
package "mdadm"

cloud_name = node[:workorder][:cloud][:ciName]

Chef::Log.info("-------------------------------------------------------------")
Chef::Log.info("Volume Size : "+size )
Chef::Log.info("-------------------------------------------------------------")

if size == "-1"
  Chef::Log.info("skipping because size = -1")
  return
end

raid_device = "/dev/md/#{node.workorder.rfcCi.ciName}"
rfc_action = "#{node.workorder.rfcCi.rfcAction}"
no_raid_device = " "

Chef::Log.info("-------------------------------------------------------------")
Chef::Log.info("Raid Device : "+raid_device)
Chef::Log.info("RFC Action  : "+rfc_action)
Chef::Log.info("-------------------------------------------------------------")

node.set["raid_device"] = raid_device
platform_name = node.workorder.box.ciName
logical_name = node.workorder.rfcCi.ciName

l_switch = size =~ /%/ ? '-l' : '-L'
f_switch = ''
_mount_point = nil
_device = nil
_fstype = nil
_options = nil
attrs = node.workorder.rfcCi.ciAttributes
if attrs.has_key?("mount_point")
  Chef::Log.info("using filesystem-in-volume logic")
  _mount_point = attrs["mount_point"]
  _device = attrs["device"]
  _options = attrs["options"]
  _fstype = attrs["fstype"]
end
_options = 'defaults' if _options.nil? || _options.empty?

if node['platform'] == 'redhat' && node['platform_version'].to_i < 7 &&
_fstype == 'xfs'
  exit_with_error('XFS filesystem is not currently supported for RedHat 6.x')
end

if node[:platform_family] == "rhel" && node[:platform_version].to_i >= 7
  Chef::Log.info("starting the logical volume manager.")
  service 'lvm2-lvmetad' do
    action [:enable, :start]
    provider Chef::Provider::Service::Systemd
  end
end

ruby_block 'create-ephemeral-volume-ruby-block' do
  # only create ephemeral if doesn't depend_on storage
  not_if { _fstype == "tmpfs" || !storage.nil? }
  block do
    #get rid of /mnt if provider added it
    initial_mountpoint = "/mnt"
    has_provider_mount = false

    `grep /mnt /etc/fstab | grep cloudconfig`
    if $?.to_i == 0
      has_provider_mount = true
    end

    if has_provider_mount
      Chef::Log.info("unmounting and clearing fstab for #{initial_mountpoint}")
      `umount #{initial_mountpoint}`
      `egrep -v "\/mnt" /etc/fstab > /tmp/fstab`
      `mv -f /tmp/fstab /etc/fstab`
    end

    devices = Array.new
    device_set = Array.new
    device_prefix = "/dev/"
    
    #Get the available devices in the baremetal node
    if ::File.exist?("/var/tmp/expected_devices")
        File.open("/var/tmp/expected_devices", "r") do |f|
          f.lines.each do |line|
            device_set.push(*line.split.map(&:to_s))
          end
        end
        Chef::Log.info("using openstack device")
        no_of_lv = device_set.size
        Chef::Log.info("No. of logical volumes: #{no_of_lv}")
    end

    df_out = `df -k`.to_s
    device_set.each do |ephemeralIndex|
      ephemeralDevice = device_prefix+ephemeralIndex
      Chef::Log.info("Ephemeral device #{ephemeralDevice}")
      if ::File.exists?(ephemeralDevice) && df_out !~ /#{ephemeralDevice}/
        # remove partitions - azure and rackspace add them
        `parted #{ephemeralDevice} rm 1`
        Chef::Log.info("removing partition #{ephemeralDevice}")
        devices.push(ephemeralDevice)
      end
    end

    total_size = 0
    device_list = ""
    
    raid_type = node.workorder.rfcCi.ciAttributes["raid_options"]

##Baremetal RAID config 
    if node.workorder.rfcCi.ciAttributes.has_raid == 'true' && raid_type == "RAID 1"
    Chef::Log.info("Raid type is #{raid_type}")

    has_created_raid = false
    exec_count = 0
    max_retry = 10
      if !devices.empty? && device_set.size%2 == 0
        devices.each do |device|
           device_list += device+" "
           Chef::Log.info("Device list is #{device_list}")
        end
           # mdadm create for RAID1
           #Check if mdadm create is already done
            mdadm_check = Mixlib::ShellOut.new("sudo mdadm --detail --scan | grep ARRAY")
            mdadm_check.run_command
            Chef::Log.info("#{mdadm_check.stdout}")
            Chef::Log.warn("#{mdadm_check.stderr}")
            puts "mdadm check exit code:" + "#{mdadm_check.exitstatus}"

            if mdadm_check.exitstatus != 0
              cmd = "yes |sudo mdadm --create --verbose #{raid_device} --level=10 --assume-clean --chunk=256 --raid-devices=#{no_of_lv} #{device_list} 2>&1"
              until ::File.exists?(raid_device) || has_created_raid || exec_count > max_retry do
              Chef::Log.info(raid_device+" being created with: "+cmd)
              mdadm_create = Mixlib::ShellOut.new("yes |sudo mdadm --create --verbose #{raid_device} --level=10 --assume-clean --chunk=256 --raid-devices=#{no_of_lv} #{device_list} 2>&1")
              mdadm_create.run_command
              Chef::Log.info("#{mdadm_create.stdout}")
              Chef::Log.warn("#{mdadm_create.stderr}")
              puts "mdadm create exit code:" + "#{mdadm_create.exitstatus}"
              mdadm_create.error!
 
              if  mdadm_create.exitstatus == 0
               has_created_raid = true
               create_mdadmdir = Mixlib::ShellOut.new("sudo mkdir -p /etc/mdadm")
               touch_mdadmconf = Mixlib::ShellOut.new("sudo touch /etc/mdadm/mdadm.conf")
               create_mdadmconf = Mixlib::ShellOut.new("sudo mdadm --detail --scan > /etc/mdadm/mdadm.conf")
               create_mdadmdir.run_command
               touch_mdadmconf.run_command
               create_mdadmconf.run_command
               puts create_mdadmdir.stderr
               puts touch_mdadmconf.stderr
               puts create_mdadmconf.stderr
               mdadm_device = Mixlib::ShellOut.new("grep ARRAY /etc/mdadm/mdadm.conf | awk '{print $2}'")
               mdadm_device.run_command
               Chef::Log.info("mdadm device is #{mdadm_device.stdout}")
               Chef::Log.warn("#{mdadm_device.stderr}")

               #pvcreate for RAID1
               existing_dev = Mixlib::ShellOut.new("pvdisplay -s")
               existing_dev.run_command
               Chef::Log.info("existing_dev is #{existing_dev.stdout}")
               Chef::Log.warn("#{existing_dev.stderr}")

               if existing_dev.stdout !~ /#{mdadm_device.stdout}/
                 Chef::Log.info("pvcreate #{mdadm_device.stdout} ...")
                 create_pv = Mixlib::ShellOut.new("pvcreate -f #{mdadm_device.stdout}")
                 create_pv.run_command
                 Chef::Log.info("#{create_pv.stdout}")
                 Chef::Log.warn("#{create_pv.stderr}")
                 create_pv.error!
               else
                 Chef::Log.info("Physical volume #{mdadm_device.stdout} is existing already.")
               end

               #vgcreate for RAID1
               vgdisplay = Mixlib::ShellOut.new("vgdisplay #{platform_name}-eph")
               vgdisplay.run_command
               Chef::Log.info("#{vgdisplay.stdout}")
               Chef::Log.warn("#{vgdisplay.stderr}")
               puts "vgdisplay exit code:" + "#{vgdisplay.exitstatus}"

               if vgdisplay.exitstatus != 0
                 Chef::Log.info("Volume group #{platform_name}-eph is not existing.")
                 Chef::Log.info("vgcreate #{platform_name}-eph #{mdadm_device.stdout} ...")
                 create_vg = Mixlib::ShellOut.new("vgcreate -f #{platform_name}-eph #{mdadm_device.stdout}")
                 create_vg.run_command
                 Chef::Log.info("#{create_vg.stdout}")
                 Chef::Log.warn("#{create_vg.stderr}")
                 create_vg.error!
               else
                 Chef::Log.warn("Volume group #{platform_name}-eph is existing already and hence cannot create ..")
               end
            else
              exec_count += 1
                sleep 10
                badarray_cleanup = Mixlib::ShellOut.new("for f in /dev/md*; do mdadm --stop $f; done")
                Chef::Log.info("cleanup bad arrays")
                badarray_cleanup.run_command
                Chef::Log.warn("#{badarray_cleanup.stderr}")
            
                mdadm_zerosupblock = Mixlib::ShellOut.new("mdadm --zero-superblock #{dev_list}")
                mdadm_zerosupblock.run_command
                Chef::Log.info("Delete mdadm superblock")
                Chef::Log.warn("#{mdadm_zerosupblock.stderr}")
            end

          end
            node.set["raid_device"] = raid_device
        else
          sleep 10
        end
      else
          Chef::Log.error("One or more device/s are in error state or no ephemerals.")
          raid_device = no_raid_device
          node.set["raid_device"] = no_raid_device    
      end
    else
          sleep 10
          mdadm_chk = Mixlib::ShellOut.new("sudo mdadm --detail --scan | grep ARRAY")
          mdadm_chk.run_command
          Chef::Log.info("#{mdadm_chk.stdout}")
          Chef::Log.warn("#{mdadm_chk.stderr}")
          puts "mdadm checking exit code:" + "#{mdadm_chk.exitstatus}"
          if mdadm_chk.exitstatus != 0
            Chef::Log.info("Raid type is RAID 0")
          #pvcreate for RAID0

            existing_pv = Mixlib::ShellOut.new("pvdisplay -s")
            existing_pv.run_command
            Chef::Log.info("existing_pv is #{existing_pv.stdout}")
            Chef::Log.warn("#{existing_pv.stderr}")
              devices.each do |device|
                dev_short = device.split("/").last
                Chef::Log.info("dev_short is #{dev_short}")
                if existing_pv.stdout !~ /#{dev_short}/
                  Chef::Log.info("pvcreate #{device} ...")
                  pvcreate = Mixlib::ShellOut.new("pvcreate -f #{device}")
                  pvcreate.run_command
                  Chef::Log.info("#{pvcreate.stdout}")
                  Chef::Log.warn("#{pvcreate.stderr}")
                  pvcreate.error!
                  device_list += device+" "
                  Chef::Log.info("device_list is #{device_list}")
                end
              end
          #vgcreate for RAID0
            if device_list != ""
                    Chef::Log.info("vgcreate #{platform_name}-eph #{device_list} ...")
                    vgcreate = Mixlib::ShellOut.new("vgcreate -f #{platform_name}-eph #{device_list}")
                    vgcreate.run_command
                    Chef::Log.info("#{vgcreate.stdout}")
                    Chef::Log.warn("#{vgcreate.stderr}")
                    vgcreate.error!
            else
            Chef::Log.info("no ephemerals.")
            end
          else
          Chef::Log.info("Raid type is RAID 1") 
          sleep 10  
     end
    end

    vgdisplay = Mixlib::ShellOut.new("vgdisplay #{platform_name}-eph")
    vgdisplay.run_command
    Chef::Log.info("#{vgdisplay.stdout}")
    Chef::Log.warn("#{vgdisplay.stderr}")
    puts "vgdisplay exit code:" + "#{vgdisplay.exitstatus}"
    if vgdisplay.exitstatus == 0
       lvdisplay = Mixlib::ShellOut.new("lvdisplay /dev/#{platform_name}-eph/#{logical_name}")
       lvdisplay.run_command
       Chef::Log.info("#{lvdisplay.stdout}")
       Chef::Log.warn("#{lvdisplay.stderr}")
       puts "lvdisplay exit code:" + "#{lvdisplay.exitstatus}"
       if lvdisplay.exitstatus != 0
          mdadm_status = Mixlib::ShellOut.new("sudo mdadm --detail --scan | grep ARRAY")
          mdadm_status.run_command
          Chef::Log.info("#{mdadm_status.stdout}")
          Chef::Log.warn("#{mdadm_status.stderr}")
          puts "mdadm status exit code:" + "#{mdadm_status.exitstatus}"
         if mdadm_status.exitstatus == 0
            Chef::Log.info("Creating logical volume #{logical_name} with  command - yes | lvcreate #{l_switch} #{size} -n #{logical_name} #{platform_name}-eph")
            lvcreate_raid1 = Mixlib::ShellOut.new("yes | lvcreate #{l_switch} #{size} -n #{logical_name} #{platform_name}-eph")
            lvcreate_raid1.run_command
            Chef::Log.info("#{lvcreate_raid1.stdout}")
            Chef::Log.warn("#{lvcreate_raid1.stderr}")
         else
            Chef::Log.info("Creating logical volume #{logical_name} with command - yes | lvcreate -i#{no_of_lv} -I32 #{l_switch} #{size} -n #{logical_name} #{platform_name}-eph")
            lvcreate_raid0 = Mixlib::ShellOut.new("yes | lvcreate -i#{no_of_lv} -I32 #{l_switch} #{size} -n #{logical_name} #{platform_name}-eph")
            lvcreate_raid0.run_command
            Chef::Log.info("#{lvcreate_raid0.stdout}")
            Chef::Log.warn("#{lvcreate_raid0.stderr}")
         end
       else
          Chef::Log.warn("logical volume #{platform_name}-eph/#{logical_name} already exists and hence cannot recreate .. prefer replacing compute")
       end
     end
  end
end

package "xfsprogs" do
  only_if { _fstype == "xfs" }
end

ruby_block 'filesystem' do
  not_if { _mount_point == nil || _fstype == "tmpfs" }
  block do
      block_dev = node.workorder.rfcCi
      _device = "/dev/#{platform_name}/#{block_dev['ciName']}"

      # if ebs/storage exists then use it, else use the -eph ephemeral volume
      if ! ::File.exists?(_device)
        _device = "/dev/#{platform_name}-eph/#{block_dev['ciName']}"

        if ! ::File.exists?(_device)
          # micro,tiny and rackspace don't have ephemeral
          Chef::Log.info("_device #{_device} don't exists")
          next
        end
      end

      include_recipe 'volume::nfs' if %w[nfs nfs4].include?(_fstype)

      Chef::Log.info("filesystem type: "+_fstype+" device: "+_device +" mount_point: "+_mount_point)
      # result attr updates cms
      Chef::Log.info("***RESULT:device="+_device)
      if rfc_action == "update"
        has_resized = false
        if _fstype == "xfs"
          `xfs_growfs #{_mount_point}`
          Chef::Log.info("Extending the xfs filesystem" )
          has_resized = true
        elsif (_fstype == "ext4" || _fstype == "ext3") && File.exists?("/dev/#{platform_name}/#{logical_name}")
          `resize2fs /dev/#{platform_name}/#{logical_name}`
          Chef::Log.info("Extending the filesystem" )
          has_resized = true
        end
        if has_resized && $? != 0
          exit_with_error "Error in extending filesystem"
        end
      end
      `mountpoint -q #{_mount_point}`
      if $?.to_i == 0
        Chef::Log.info("device #{_mount_point} already mounted.")
        next
      end

      type = (`file -sL #{_device}`).chop.split(" ")[1]

      Chef::Log.info("-------------------------")
      Chef::Log.info("Type : = "+type )
      Chef::Log.info("-------------------------")

      if type == 'data'
        cmd = "mkfs -t #{_fstype} #{f_switch} #{_device}"
        execute_command(cmd, true)
      end

      # in-line because of the ruby_block doesn't allow updated _device value passed to mount resource
      `mkdir -p #{_mount_point}`
      `mount -t #{_fstype} -o #{_options} #{_device} #{_mount_point}`

      # clear and add to fstab again to make sure has current attrs on update
      `grep -v #{_device} /etc/fstab > /tmp/fstab`
      ::File.open("/tmp/fstab","a") do |fstab|
        fstab.puts("#{_device} #{_mount_point} #{_fstype} #{_options} 1 1")
        Chef::Log.info("adding to fstab #{_device} #{_mount_point} #{_fstype} #{_options} 1 1")
      end
      `mv /tmp/fstab /etc/fstab` 
  end
end

ruby_block 'ramdisk tmpfs' do
  only_if { _fstype == "tmpfs" }
  block do

    # Unmount existing mount for the same mount_point
    `mount | grep #{_mount_point}`
    if $?.to_i == 0
      Chef::Log.info("device #{_device} for mount-point #{_mount_point} already mounted.Will unmount it.")
      result=`umount #{_mount_point}`
      Chef::Log.error("umount error: #{result.to_s}") if result.to_i != 0
    end

    Chef::Log.info("mounting ramdisk :: filetype:#{_fstype} dir:#{_mount_point} device:#{_device} size:#{size} options:#{_options}")

    # Make directory if not existing
    `mkdir -p #{_mount_point}`
    result=`mount -t #{_fstype} -o size=#{size} #{_fstype} #{_mount_point}"`
    Chef::Log.error("mount error: #{result.to_s}") if result.to_i != 0

    # clear existing mount_point and add to fstab again to ensure update attributes and to persist the ramdisk across reboots
    `grep -v #{_mount_point} /etc/fstab > /tmp/fstab`
    ::File.open("/tmp/fstab","a") do |fstab|
      fstab.puts("#{_device} #{_mount_point} #{_fstype} #{_options},size=#{size}")
      Chef::Log.info("adding to fstab #{_device} #{_mount_point} #{_fstype} #{_options}")
    end
    `mv /tmp/fstab /etc/fstab`
  end
end
