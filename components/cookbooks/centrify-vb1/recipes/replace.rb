# Replace - Replaces all components
#
# This recipe replaces all components used for Centrify
# with the settings they are supposed to be at.

Chef::Log.info("Running #{node['app_name']}::replace")

include_recipe "#{node['app_name']}::add"
