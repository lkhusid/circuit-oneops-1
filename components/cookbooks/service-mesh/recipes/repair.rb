svrname = node['hostname']
Chef::Log.info("Performing repair on server: #{svrname}")

include_recipe "service-mesh::replace"
Chef::Log.info("Repair completed")
