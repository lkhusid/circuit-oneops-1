# join_zone - Join the Centrify zone
#
# This recipe joins the server to the Centrify zone.

Chef::Log.info("Running #{node['app_name']}::join_zone")

require File.expand_path("../centrify_helper.rb", __FILE__)

configName = node['app_name']
configNode = node[configName]

cent_cache_path = Chef::Config[:file_cache_path]

# Check to make sure the variables are set
centrifydc_User = nil
centrifydc_Pwd = nil

serviceConfig = get_service_config()

if serviceConfig.nil?
  # The service hasn't been configured.  Raise an error with a
  # helpful message.
  raise_service_exception()
end

instance_number = node.workorder.rfcCi.ciName.split('-')[-1]

# Pull the config values
zone_name = serviceConfig[:zone_name]

local_zone = configNode['centrify_zone']
if !local_zone.nil? && local_zone != ''
  zone_name = local_zone
end

centrifydc_User = serviceConfig[:zone_user]
centrifydc_Pwd = serviceConfig[:zone_pwd]
domain_name = serviceConfig[:domain_name]
ldap_container = serviceConfig[:ldap_container]
# compute instance id--instance number--assembly name
computer_account = "#{node.workorder.payLoad.RealizedAs[0].ciId}-#{instance_number}-#{node.workorder.payLoad.Assembly[0].ciName}"
# compute instance id--environment name--assembly name
computer_alias = "#{node.workorder.payLoad.ManagedVia[0].ciId}-#{node.workorder.payLoad.Environment[0].ciName}-#{node.workorder.payLoad.Assembly[0].ciName}"
# oneops--compute instance id
computer_short_name = "oneops-#{node.workorder.payLoad.ManagedVia[0].ciId}"

# Continue with the join
Chef::Log.info("Zone information:")
Chef::Log.info("Zone Name: #{zone_name}")
Chef::Log.info("Domain Name: #{domain_name}")
Chef::Log.info("LDAP Container: #{ldap_container}")
Chef::Log.info("Computer Account: #{computer_account}")
Chef::Log.info("Computer Alias: #{computer_alias}")
Chef::Log.info("Computer Short Name: #{computer_short_name}")

# When running the commands to leave the zone, be sure to mask
# credentials so that they aren't put into the output.

joinOpts = ""
if node.workorder.rfcCi.rfcAction == "replace"
  # During a replace operation, when joining, perform a force.
  joinOpts = "--force"
end

previousDC = node.workorder.rfcCi.ciAttributes["domain_controller"]
if previousDC != nil
  previousDC = previousDC.strip
  
  if previousDC != ""
    dcOverride = previousDC
    joinOpts = joinOpts + " -s #{dcOverride}"
  end
end

ruby_block "do_join_zone" do
  block do
    credString = "-u \"#{centrifydc_User}\" -p \"#{centrifydc_Pwd}\""
    cleanCredString = "-u \"****\" -p \"****\""

    cmd = Mixlib::ShellOut.new("adjoin -z \"#{zone_name}\" #{credString} -c \"#{ldap_container}\" \"#{domain_name}\" -n \"#{computer_account}\" -a \"#{computer_alias}\" -N \"#{computer_short_name}\" #{joinOpts}")
    cmd.user = 'root'
    cmd.run_command

    # Clean credentials out of the string
    cleanString = cmd.format_for_exception.gsub(credString, cleanCredString)

    Chef::Log.info("Execution completed\n#{cleanString}")

    if cmd.error?
      puts "***FAULT:FATAL=The Zone could not be joined."
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e
    else
      cmdGetDC = Mixlib::ShellOut.new("adinfo |grep 'Current DC' |awk '{ print $3; }'")
      cmdGetDC.run_command

      domain_controller=cmdGetDC.stdout

      puts "***RESULT:cdc_account_name=#{computer_account}"
      puts "***RESULT:cdc_short_name=#{computer_short_name}"
      puts "***RESULT:cdc_alias=#{computer_alias}"
      puts "***RESULT:domain_controller=#{domain_controller}"
    end
  end
  not_if "/usr/bin/adinfo"
end

# If a parent location for user directories has been
# specified, create it now.
userDirParent = serviceConfig[:user_dir_parent]

directory "create_user_dir_parent" do
  path  userDirParent
  owner 'root'
  group 'root'
  mode  '0755'
  recursive true
  only_if { not userDirParent.empty? }
end
