Chef::Log.info("Going to stop BaaS driver...")

processOwner = "#{node['baas-job']['process-owner']}"

execute 'stopBaasDriver' do
	command "#{node['baas-job']['init-name']} stop"
	user	processOwner
	ignore_failure true
	returns [0,1]
end

Chef::Log.info("Baas driver stopped")
