Chef::Log.info("Executing baas-job.replace() recipe")
svrname = node['hostname']
Chef::Log.info("Using server: #{svrname}")

include_recipe "baas-job::delete"
include_recipe "baas-job::add"
