Chef::Log.info("Executing service-mesh.add() recipe")
svrname = node['hostname']
Chef::Log.info("Using server: #{svrname}")

include_recipe "service-mesh::default"
