Chef::Log.info("Restarting baas driver...")
execute 'restartBaasDriver' do
	command "#{node['baas-job']['init-name']} restart"
	user	'root'
end
Chef::Log.info("BaaS driver restarted successfully.")
