serviceMeshRootDir = "#{node['service-mesh']['service-mesh-root']}"

directory serviceMeshRootDir do
  recursive true
  action :delete
end
Chef::Log.info("Service mesh root directory deleted := #{serviceMeshRootDir}")
