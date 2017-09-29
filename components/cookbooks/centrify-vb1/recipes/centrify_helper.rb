# centrify_helper - Library functions
#
# These functions contain logic that is shared across multiple components.

# Get the centrify configuration from the Centrify service.
#
# RETURNS:
# A hash that contains the following values:
#   url - The url to get the RPM from
#   zone - The name of the zone to join
#   ldap_container - The LDAP container to create the server in
#   domain_name - The name of the domain to join
#   user_dir_parent - The directory that contains the user home directories
#   centrifydc_User - The username to use for accessing the directory
#   centrifydc_Pwd - The password for accessing the directory
#
def get_service_config()
  # Create an empty hash...the values will be filled in
  serviceConfig = Hash.new
  
  directory_service = "centrify"
  
  cloud_name = node[:workorder][:cloud][:ciName]
  
  centrifydc_User = nil
  centrifydc_Pwd = nil
  
  if (!node[:workorder][:services][directory_service].nil?)
    attrMap = node[:workorder][:services][directory_service][cloud_name][:ciAttributes]

    serviceConfig[:url] = attrMap['centrify_url']
    serviceConfig[:zone_name] = attrMap['centrify_zone']
    serviceConfig[:zone_user] = attrMap['zone_user']
    serviceConfig[:zone_pwd] = attrMap['zone_pwd']
    serviceConfig[:ldap_container] = attrMap['ldap_container']
    serviceConfig[:domain_name] = attrMap['domain_name']
    serviceConfig[:user_dir_parent] = attrMap['user_dir_parent']

  else
    puts "CENTRIFY: Couldn't find Centrify service"
    serviceConfig = nil
  end
  
  return serviceConfig
end

# Raises an exception because the service is not configured.
#
def raise_service_exception()
  puts "***FAULT:FATAL=The Centrify service is not configured for this cloud.  Please make sure there is a Centrify service configured."
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end
