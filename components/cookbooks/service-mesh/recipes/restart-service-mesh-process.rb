Chef::Log.info("Restarting service mesh...")
execute 'startServiceMesh' do
	command "#{node['service-mesh']['init-name']} restart"
	user	'root'
end
Chef::Log.info("Service mesh restarted successfully.")
