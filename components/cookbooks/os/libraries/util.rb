
#require 'chef'
def exit_with_error(msg)
	puts "***FAULT:FATAL=#{msg}"
	Chef::Application.fatal!(msg)
end

#-----------------------add-conf-files.rb-----------------------
def get_prefix(ostype)
	prefix = ''
	prefix = 'C:' if ostype =~ /windows/

	return prefix
end

def get_cloud_environment_vars(node)

	cloud_name = node[:workorder][:cloud][:ciName]
	compute_cloud_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
	env_vars = {}

	if compute_cloud_service.has_key?("env_vars")
		env_vars = JSON.parse(compute_cloud_service[:env_vars])
	end
	return env_vars
end

def get_os_environment_vars(node)
	env_vars = {}
	if node.workorder.rfcCi.ciAttributes.has_key?('env_vars') &&
			!node.workorder.rfcCi.ciAttributes.env_vars.empty?
		env_vars = JSON.parse(node.workorder.rfcCi.ciAttributes.env_vars)
	end
	return env_vars
end

def get_oneops_vars(node)

	cloud_name = node[:workorder][:cloud][:ciName]
	compute_cloud_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

	if node.workorder.cloud.ciAttributes.has_key?("priority") &&
			node.workorder.cloud.ciAttributes.priority.to_i == 1
		cloud_priority = "primary"
	else
		cloud_priority = "secondary"
	end

	provider = node[:workorder][:services][:compute][cloud_name][:ciClassName].gsub("cloud.service.","").downcase.split(".").last

	if provider =~ /azure/
		cloud_tenant = node[:workorder][:payLoad][:Organization][0][:ciName]
	else
		cloud_tenant = compute_cloud_service[:tenant]
	end

	vars =  {
			:ONEOPS_NSPATH =>  node[:workorder][:rfcCi][:nsPath],
			:ONEOPS_PLATFORM => node[:workorder][:box][:ciName],
			:ONEOPS_ASSEMBLY => node[:workorder][:payLoad][:Assembly][0][:ciName],
			:ONEOPS_ENVIRONMENT => node[:workorder][:payLoad][:Environment][0][:ciName],
			:ONEOPS_ENVPROFILE => node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile],
			:ONEOPS_CI_NAME => node[:workorder][:rfcCi][:ciName],
			:ONEOPS_COMPUTE_CI_ID => node.workorder.payLoad.ManagedVia[0]["ciId"],
			:ONEOPS_CLOUD => node[:workorder][:cloud][:ciName],
			:ONEOPS_CLOUD_AVAIL_ZONE => node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["availability_zone"],
			:ONEOPS_CLOUD_COMPUTE_SERVICE =>node[:workorder][:services][:compute][cloud_name][:ciName],
			:ONEOPS_CLOUD_REGION => compute_cloud_service[:region],
			:ONEOPS_CLOUD_ADMINSTATUS => cloud_priority,
			:ONEOPS_CLOUD_TENANT => cloud_tenant
	}
	return vars
end

def get_cloud_env_vars_content(node)
	env_vars_content = ""
	env_vars = get_cloud_environment_vars(node)

	env_vars.keys.each do |k|
		env_vars_content += "export #{k}=#{env_vars[k]}\n"
	end
	return env_vars_content
end

def get_oo_vars_content(node)
	oo_vars_content = ""
	env_vars = get_os_environment_vars(node)
	vars = get_oneops_vars(node)
	vars.each do |k,v|
		oo_vars_content += "export #{k}=#{v}\n"
	end
	env_vars.each do |k, v|
		oo_vars_content += "export #{k}=#{v}\n"
	end

	oo_vars_content = oo_vars_content + get_cloud_env_vars_content(node)

	return oo_vars_content
end

def get_oo_vars_conf_content(node)
	oo_vars_conf_content=""
	env_cloud_vars = get_cloud_environment_vars(node)
	env_os_vars = get_os_environment_vars(node)
	env_oneops_vars = get_oneops_vars(node)

	env_cloud_vars.keys.each do |k|
		oo_vars_conf_content += "#{k}=#{env_cloud_vars[k]}\n"
	end
	env_oneops_vars.each do |k,v|
		oo_vars_conf_content += "#{k}=#{v}\n"
	end
	env_os_vars.each do |k, v|
		oo_vars_conf_content += "#{k}=#{v}\n"
	end


	return oo_vars_conf_content
end

def is_propagate_update
	rfcCi = node.workorder.rfcCi
	if (rfcCi.ciBaseAttributes.nil? || rfcCi.ciBaseAttributes.empty?) && rfcCi.has_key?('hint') && !rfcCi.hint.empty?
		hint = JSON.parse(rfcCi.hint)
		puts "rfc hint >> " + rfcCi.hint.inspect
		if hint.has_key?('propagation') && hint['propagation'] == 'true'
			return true;
		end
	end
	return false
end
#-----------------------add-conf-files.rb-----------------------
