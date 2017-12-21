# Restart - Restarts the Spark components.
#
# This recipe restarts the Spark service on the compute.

Chef::Log.info("Running #{node['app_name']}::restart")

# Include the restart recipe.
include_recipe "#{node['app_name']}::spark_restart"
