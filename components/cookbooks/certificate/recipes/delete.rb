#if key-managment service barbican is present in the workload , invoke the barbican::delete recipe here
if node[:workorder][:services].has_key?("keymanagement")
  include_recipe "barbican::delete"
end

cloud_name = node[:workorder][:cloud][:ciName]
provider = ""
auto_provision = node.workorder.rfcCi.ciAttributes.auto_provision
cert_service = node[:workorder][:services][:certificate]

if ! cert_service.nil? && ! cert_service[cloud_name].nil?
        provider = node[:workorder][:services][:certificate][cloud_name][:ciClassName].gsub("cloud.service.","").downcase.split(".").last
elsif !auto_provision.nil? && auto_provision == "true"
        Chef::Log.error("Certificate cloud service not defined for this cloud")
        exit 1
end

if !auto_provision.nil? && auto_provision == "true" && !provider.nil? && !provider.empty?
        include_recipe provider + "::delete_certificate"
end

