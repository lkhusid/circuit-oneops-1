Chef::Log.info("Executing baas-job.delete() recipe")
svrname = node['hostname']
Chef::Log.info("Using server: #{svrname}")

include_recipe "baas-job::stop"

appUser = "#{node['baas-job']['app-user']}"
baasContext = "#{node['baas-job']['baas-context']}"
baasDir = "/" + appUser + "/" + baasContext
jobsDir = baasDir + "/jobs"
driverDir =  baasDir + "/" + "#{node['baas-job']['baas-driver-dir']}"

directory jobsDir do
  recursive true
  action :delete
end
Chef::Log.info("Baas jobs directory deleted := #{jobsDir}")

directory driverDir do
  recursive true
  action :delete
end
Chef::Log.info("Baas driver directory deleted := #{driverDir}")

file '/etc/init.d/baasdriver' do
  action :delete
  ignore_failure true
end
Chef::Log.info("Baas driver init.d script deleted.")
