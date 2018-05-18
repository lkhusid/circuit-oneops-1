svrname = node['hostname']
Chef::Log.info("Performing replace for service-mesh on host: #{svrname}")
include_recipe "service-mesh::delete"
include_recipe "service-mesh::add"
Chef::Log.info("Replace completed")
