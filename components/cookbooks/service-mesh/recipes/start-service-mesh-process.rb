Chef::Log.info("Starting service mesh...")
execute 'startServiceMesh' do
	command "#{node['service-mesh']['init-name']} start"
	user	'root'
end
Chef::Log.info("Service mesh started successfully.")
