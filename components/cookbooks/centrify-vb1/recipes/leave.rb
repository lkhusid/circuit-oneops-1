# Leave - Run the 'leave' action
#
# This recipe runs the "leave" action to leave AD.

Chef::Log.info("Running #{node['app_name']}::leave")

# Look up the service configuration
serviceConfig = get_service_config()

if serviceConfig.nil?
  # The Centrify service is not configured.  Raise an error with a
  # helpful message.
  raise_service_exception()
end

centrifydc_User = serviceConfig[:zone_user]
centrifydc_Pwd = serviceConfig[:zone_pwd]

# When running the commands to leave the zone, be sure to mask
# credentials so that they aren't put into the output.

ruby_block "do_leave_zone" do
  block do
    credString = "-u \"#{centrifydc_User}\" -p \"#{centrifydc_Pwd}\""
    cleanCredString = "-u \"****\" -p \"****\""

    cmd = Mixlib::ShellOut.new("adleave -r #{credString}")
    cmd.user = 'root'
    cmd.run_command

    # Clean credentials out of the string
    cleanString = cmd.format_for_exception.gsub(credString, cleanCredString)

    Chef::Log.info("Execution completed\n#{cleanString}")
  end
end

Chef::Log.info("#{node['app_name']}::leave completed")

