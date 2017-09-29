# Repair - Repairs the Centrify components.
#
# This recipe ensures that all of the Centrify
# components are configured properly.

Chef::Log.info("Running #{node['app_name']}::repair")

# Run the add recipe again to repair the installation.
include_recipe "#{node['app_name']}::add"
