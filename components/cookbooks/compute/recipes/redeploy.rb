

cloud_name = node[:workorder][:cloud][:ciName]
provider = node[:workorder][:services][:compute][cloud_name][:ciClassName].gsub("cloud.service.","").downcase
if provider =~ /azure/
  include_recipe "azure::redeploy_node"
  if node[:redeploy_result] == "Error"
    e = Exception.new("no backtrace")
    e.set_backtrace("no backtrace")
    raise e
  end
  Chef::Log.info("successfully redelpoyed the compute")
else
  Chef::Log.info("This operation is not supported on #{provider}")
end