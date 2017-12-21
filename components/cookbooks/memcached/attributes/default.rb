default["memcached"]["port"]               = '11211'
default["memcached"]["ipaddress"]          = '0.0.0.0'
default["memcached"]["log_file"]           = '/var/log/memcached.log'
default["memcached"]["max_memory"]         = '1024'
default["memcached"]["max_connections"]    = '1024'
default["memcached"]["user"]               = 'memcached'
default["memcached"]["log_level"]          = 'disabled'
default["memcached"]["num_threads"]        = "4"
default["memcached"]["enable_cas"]         = "true"
default["memcached"]["enable_error_on_memory_ex"] = "false"
default["memcached"]["additional_cli_opts"] = '[]'


cloud_name = node[:workorder][:cloud][:ciName]

if node[:workorder][:services].has_key?("mirror") &&
   node[:workorder][:services]["mirror"][cloud_name][:ciAttributes].has_key?("mirrors")

  mirror_vars = JSON.parse( node[:workorder][:services]["mirror"][cloud_name][:ciAttributes][:mirrors] )
  if mirror_vars.has_key?('memcached')
    default['memcached']['base_url'] = mirror_vars['memcached']
  else
    Chef::Log.info("memcached does not have mirror service included")
  end
else
  Chef::Log.info("memcached does not have mirror service included")
end


default['memcached']['package_name']       = 'memcached'
default['memcached']['version']            = 'repo'
default['memcached']['arch']               = 'x86_64'
default['memcached']['pkg_type']           = 'rpm'
