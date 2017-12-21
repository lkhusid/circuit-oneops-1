# Delete the node and re-replicate its data to the remaining nodes 
# via nodetool decommission.
# This is a best-effort recipe.  If it fails, OneOps will ignore
# the failure and continue.  The Ring component will run
# nodetool removenode and repair if the node was not decommissioned.
nodes = node.workorder.payLoad.RequiresComputes
remaining = nodes.reject { |n| n[:rfcAction] == 'delete' }
local_ip = node[:ipaddress]
cassandra_home = node[:cassandra_home]
cassandra_current = "#{cassandra_home}/current"

if remaining.empty?
  Chef::Log.info("No nodes remaining, proceeding with cassandra delete without a decommission")
else
  availability_mode = node.workorder.box.ciAttributes.availability
  if availability_mode != "single"
    # Restart if state not normal
    # Start if not running
    info = Cassandra::Util.nodetool_info()
    unless !info.nil? && info['Gossip active'] == 'true' && info['Native Transport active'] == 'true'
      include_recipe 'apache_cassandra::restart'
    end

    execute "decommission" do
      command "#{cassandra_current}/bin/nodetool decommission && sleep 30"
    end
  end
end
node.default[:initial_seeds] = Cassandra::Util.find_seeds(node, local_ip)
include_recipe "apache_cassandra::update_seeds"

service "cassandra" do
  action [ :disable, :stop ]
end
