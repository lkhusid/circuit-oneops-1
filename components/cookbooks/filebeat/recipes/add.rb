include_recipe "filebeat::pkg_install"
include_recipe "filebeat::setup"
enable = node['filebeat']['enable_agent']
Chef::Log.info("DEBUG-enable=" + enable)
if node['filebeat']['enable_agent'] == 'true'
  Chef::Log.info("DEBUG-starting...")
  include_recipe "filebeat::start"
end
