# Add - Add the Centrify components
#
# This recipe installs all of the components that are required for
# a functional Centrify installation.

Chef::Log.info("Running #{node['app_name']}::add")

# Install basic system packages
include_recipe "#{node['app_name']}::prerequisites"

# Install the RPM
include_recipe "#{node['app_name']}::install_rpm"

# Update the config file
include_recipe "#{node['app_name']}::update_config"

# Join the zone
include_recipe "#{node['app_name']}::join_zone"

Chef::Log.info("#{node['app_name']}::add completed")
