# Cloud RDBMS wire_ci_attr.rb
# Massage the workorder attributes to make them nicer for the scripts.
#

# Get all component attributes
ci = node.workorder.rfcCi.ciAttributes

node.set['cloudrdbms']['clustername'] = ci['clustername']
node.set['cloudrdbms']['drclouds'] = ci['drclouds']
node.set['cloudrdbms']['cloudrdbmspackversion'] = ci['cloudrdbmspackversion']

node.set['cloudrdbms']['concordaddress'] = ci['concordaddress']
node.set['cloudrdbms']['managedserviceuser'] = ci['managedserviceuser']
node.set['cloudrdbms']['managedservicepass'] = ci['managedservicepass']