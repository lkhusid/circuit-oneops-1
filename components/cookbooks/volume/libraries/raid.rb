def check_raid(raid_name)
  cmd = "mdadm --detail --scan | grep #{raid_name}"
  rc = execute_command(cmd)
  if rc.valid_exit_codes.include?(rc.exitstatus)
    conf = rc.stdout.chomp
    return true, conf.split(' ')[1],rc.stdout.chomp
  else
    return false, nil, nil
  end
end


def get_raid_device(raid_name)
  check_raid(raid_name)[1]
end


def raid_exist?(raid_name)
  check_raid(raid_name)[0]
end
