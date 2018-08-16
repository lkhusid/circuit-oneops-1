Chef::Log.info("Executing baas-job.add() recipe")
svrname = node['hostname']
Chef::Log.info("Using server: #{svrname}")

include_recipe "baas-job::default"
