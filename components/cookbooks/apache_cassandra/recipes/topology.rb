cassandra_home = node.default[:cassandra_home]
cassandra_current = "#{cassandra_home}/current"

puts "***RESULT:node_ip=#{node.workorder.payLoad.ManagedVia[0][:ciAttributes][:private_ip]}"

if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
  actionName = node.workorder.rfcCi.rfcAction
else
  ci = node.workorder.ci
  actionName = node.workorder.actionName
end

if ci.ciAttributes.endpoint_snitch !~ /PropertyFileSnitch/
  Chef::Log.info("snitch: #{ci.ciAttributes.endpoint_snitch} no topology file needed")
  return
end

# maintain the topology on updates or if its a PFS
if (actionName != "add" && actionName != "replace" && 
    ci.ciAttributes.endpoint_snitch !~ /PropertyFileSnitch/
    ) || ci.ciAttributes.endpoint_snitch =~ /\.PropertyFileSnitch/

  template "#{cassandra_current}/conf/cassandra-topology.properties" do
    source "cassandra-topology.properties.erb"
  end
else
  execute "rm -f #{cassandra_current}/conf/cassandra-topology.properties"
end

template "#{cassandra_current}/conf/cassandra-rackdc.properties" do
  source "cassandra-rackdc.properties.erb"
end