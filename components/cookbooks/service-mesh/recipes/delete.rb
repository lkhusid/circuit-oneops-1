Chef::Log.info("Executing service-mesh.delete() recipe")
include_recipe "service-mesh::stop-service-mesh-process"
include_recipe "service-mesh::cleanup"
Chef::Log.info("service-mesh.delete() completed")
