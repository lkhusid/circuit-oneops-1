# Replace - Replaces all components
#
# This recipe is called when the compute that the Presto_cluster
# component is installed to is replaced.

# By default, perform an add
include_recipe "#{node['app_name']}::add"
