Chef::Log.info("Executing baas-job.repair() recipe")
svrname = node['hostname']
Chef::Log.info("Using server: #{svrname}")

include_recipe "baas-job::replace"
