# Delete - Delete the Centrify components
#
# This recipe removes all components used for Centrify

Chef::Log.info("Running #{node['app_name']}::delete")

require File.expand_path("../centrify_helper.rb", __FILE__)

cache_path = Chef::Config[:file_cache_path]

configName = node['app_name']
configNode = node[configName]

# Leave the zone

# Check to make sure the variables are set
centrifydc_User = nil
centrifydc_Pwd = nil

serviceConfig = get_service_config()

if serviceConfig.nil?
  # The Centrify service isn't configured.  Raise an error with a
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

# Remove the package
execute "remove_centrify" do
  user    "root"
  command "rpm -e `rpm -qa |grep -i centrify`"
  only_if "rpm -qa |grep -i centrify"
end

Chef::Log.info("#{node['app_name']}::delete completed")
