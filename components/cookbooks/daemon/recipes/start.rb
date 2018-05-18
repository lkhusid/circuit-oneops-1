#
# Cookbook Name:: daemon
# Recipe:: start
#
attrs = node.workorder.ci.ciAttributes
service_name = attrs[:service_name]
pat = attrs[:pattern] || ''

service_type = nil
initService = "/etc/init.d/#{service_name}"
systemdService = "/usr/lib/systemd/system/#{service_name}.service"

if File.exist?(systemdService)
	service_type = "systemd"
elsif File.exist?(initService)
	service_type = "init"
end

# start daemon service when pattern has not been specified
ruby_block "start #{service_name} service" do
	block do
    	Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    	shell_out!("service #{service_name} start", :live_stream => Chef::Log::logger)
	end
  	only_if { pat.empty? }
end

# start daemon service when pattern has been specified
service "#{service_name}" do
	provider Chef::Provider::Service::Init if service_type == "init" && node[:platform_family].include?("rhel")
	pattern "#{pat}"
	action :start
	only_if { !pat.empty? }
end
