default['mcrouter']['root_dir'] = '/opt/mcrouter'
default['mcrouter']['src_dir'] = "#{node['mcrouter']['root_dir']}/mcrouter"
default['mcrouter']['log_dir'] = "#{node['mcrouter']['root_dir']}/log"
default['mcrouter']['install_dir'] = '/opt/mcrouter/install'
default['mcrouter']['user'] = 'mcrouter'


cloud_name = node[:workorder][:cloud][:ciName]


if node[:workorder][:services].has_key?("mirror") &&
    node[:workorder][:services]["mirror"][cloud_name][:ciAttributes].has_key?("mirrors")

  mirror_vars = JSON.parse( node[:workorder][:services]["mirror"][cloud_name][:ciAttributes][:mirrors] )
  if mirror_vars.has_key?('mcrouter')
    default['mcrouter']['base_url'] = mirror_vars['mcrouter']
  else
    Chef::Log.info("McRouter does not have mirror service included")
  end
else
  Chef::Log.info("McRouter does not have mirror service included")
end


default['mcrouter']['package_name'] = 'mcrouter'
default['mcrouter']['version']= '0.26.0-1.el7'
default['mcrouter']['arch'] = 'x86_64'
default['mcrouter']['pkg_type'] = 'rpm'
default['mcrouter']['sha256'] = ''

default['mcrouter']['port']        = '5000'
default['mcrouter']['config-file'] = '/etc/mcrouter/mcrouter.json'
default['mcrouter']['async-dir']   = "#{node['mcrouter']['log_dir']}/var/spool/mcrouter"
default['mcrouter']['pool_group_by']   = 'Cloud'

#log-path no longer used
default['mcrouter']['log-path']    = "#{node['mcrouter']['log_dir']}/mcrouter/mcrouter.log"
default['mcrouter']['pid-file']    = '/var/run/mcrouter/mcrouter.pid'
default['mcrouter']['stats-root']  = "#{node['mcrouter']['log_dir']}/var/mcrouter/stats"


default['mcrouter']['enable_asynclog'] = 'true'
default['mcrouter']['enable_flush_cmd'] = 'false'
default['mcrouter']['enable_logging_route'] = 'false'
default['mcrouter']['num_proxies'] = '1'
default['mcrouter']['server_timeout'] = '1000'
default['mcrouter']['verbosity'] = 'disabled'
default['mcrouter']['miss_limit'] = '2'
default['mcrouter']['additional_cli_opts'] = '[]'

    
# Supported data policies
# AllAsyncRoute (default) : get/gets uses MissFailoverRoute, all other operations use AllAsyncRoute
# AllSyncRoute : get/gets uses MissFailoverRoute, all other operations use AllSyncRoute
# AllInitialRoute : get/gets uses MissFailoverRoute, all other operations use AllInitialRoute
# AllFastestRoute : get/gets uses MissFailoverRoute, all other operations use AllFastestRoute
# AllMajorityRoute : get/gets uses MissFailoverRoute, all other operations use AllMajorityRoute
#
default['mcrouter']['policy'] = 'AllAsyncRoute'
  
  
# Supported Routes:
# PoolRoute (default) : Original route used by pack
# HashRouteSalted : Use salted hash to server pool 
default['mcrouter']['route'] = 'PoolRoute' 
