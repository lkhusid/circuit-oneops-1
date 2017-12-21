# Cloud RDBMS wire_ci_attr.rb
# Massage the workorder attributes to make them nicer for the scripts.
#

# Get all component attributes
ci = node.workorder.rfcCi.ciAttributes
cibase = node.workorder.rfcCi.ciBaseAttributes
env_name = node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile].downcase

log "CloudRDBMS Wiring OneOps CI attributes : #{ci.to_json}"

node.set['cloudrdbms']['urlbase'] = ci['urlbase']
node.set['cloudrdbms']['clustername'] = ci['clustername']
node.set['cloudrdbms']['runOnEnv'] = env_name
log "CloudRDBMS Setting run environment to: '#{node['cloudrdbms']['runOnEnv']}'"
node.set['cloudrdbms']['drclouds'] = ci['drclouds']
node.set['cloudrdbms']['cloudrdbmspackversion'] = ci['cloudrdbmspackversion']
  
node.set['cloudrdbms']['artifacturlbase'] = ci['artifacturlbase']
  
node.set['cloudrdbms']['concordaddress'] = ci['concordaddress']
node.set['cloudrdbms']['managedserviceuser'] = ci['managedserviceuser']
node.set['cloudrdbms']['managedservicepass'] = ci['managedservicepass']