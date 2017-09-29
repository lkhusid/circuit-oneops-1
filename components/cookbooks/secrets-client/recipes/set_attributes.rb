cloud_name = node.workorder.cloud.ciName

secret_service = node[:workorder][:services][:secret]
provider = ""
if ! secret_service.nil? && ! secret_service[cloud_name].nil?
        provider = secret_service[cloud_name][:ciClassName].gsub("cloud.service.","").downcase.split(".").last
else
        msg = "Secret cloud service not defined for this cloud"
        Chef::Log.error(msg)
        puts "***FAULT:FATAL=#{msg}"
        Chef::Application.fatal!(msg)
end
node.set[:provider] = provider


