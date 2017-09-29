# Join - Run the 'join' action
#
# This recipe runs the "join" action to join AD using the configured information.

Chef::Log.info("Running #{node['app_name']}::join")

# Look up the service configuration

configName = node['app_name']
configNode = node[configName]

serviceConfig = get_service_config()

if serviceConfig.nil?
  # The service is not configured.  Raise an error with a
  # helpful message.
  raise_service_exception()
end

centrifydc_User = serviceConfig[:zone_user]
centrifydc_Pwd = serviceConfig[:zone_pwd]

# This is run in an action, so read information from the
# node.workorder.ci item instead of node.workorder.rfcCi
instance_number = node.workorder.ci.ciName.split('-')[-1]

compute_metadata = node.workorder.payLoad.ManagedVia[0].ciAttributes["metadata"]

assembly_name = JSON.parse(compute_metadata)["assembly"]

# Pull the config values
zone_name = serviceConfig[:zone_name]

local_zone = configNode['centrify_zone']
if !local_zone.nil? && local_zone != ''
  zone_name = local_zone
end

domain_name = serviceConfig[:domain_name]
ldap_container = serviceConfig[:ldap_container]
# compute instance id--instance number--assembly name
computer_account = "#{node.workorder.payLoad.RealizedAs[0].ciId}-#{instance_number}-#{assembly_name}"
# compute instance id--environment name--assembly name
computer_alias = "#{node.workorder.payLoad.ManagedVia[0].ciId}-#{node.workorder.payLoad.Environment[0].ciName}-#{assembly_name}"
# oneops--compute instance id
computer_short_name = "oneops-#{node.workorder.payLoad.ManagedVia[0].ciId}"

# When running the commands to leave the zone, be sure to mask
# credentials so that they aren't put into the output.

ruby_block "do_join_zone" do
  block do
    credString = "-u \"#{centrifydc_User}\" -p \"#{centrifydc_Pwd}\""
    cleanCredString = "-u \"****\" -p \"****\""

    cmd = Mixlib::ShellOut.new("adjoin -z \"#{zone_name}\" #{credString} -c \"#{ldap_container}\" \"#{domain_name}\" -n \"#{computer_account}\" -a \"#{computer_alias}\" -N \"#{computer_short_name}\"")
    cmd.user = 'root'
    cmd.run_command

    # Clean credentials out of the string
    cleanString = cmd.format_for_exception.gsub(credString, cleanCredString)

    Chef::Log.info("Execution completed\n#{cleanString}")
  end
end

Chef::Log.info("#{node['app_name']}::join completed")

