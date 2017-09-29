case node.platform
when "windows"
  include_recipe "telegraf::pkg_install_win"
else
  include_recipe "telegraf::pkg_install"
  include_recipe "telegraf::setup"

  enable = node['telegraf']['enable_agent']
  Chef::Log.info("DEBUG-enable=" + enable)
  if node['telegraf']['enable_agent'] == 'true'
    Chef::Log.info("DEBUG-starting...")
    include_recipe "telegraf::start"
  end
end
