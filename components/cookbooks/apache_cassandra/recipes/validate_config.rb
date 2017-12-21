require 'json'
require 'yaml'

ci = node.workorder.has_key?("rfcCi")?node.workorder.rfcCi : node.workorder.ci
actionName = node.workorder.has_key?("rfcCi")?node.workorder.rfcCi.rfcAction : node.workorder.actionName
cluster_name = ci.ciAttributes.cluster
if cluster_name == 'TestCluster'
  puts "Re-assigning cluster_name from \"#{cluster_name}\" to empty string"
  cluster_name = ''
end
msg = ''
invalid_cluster = false

#validate cluster name with value in cassandra.yaml for existing nodes
if actionName =~ /update|upgrade/
  yaml_file = "/opt/cassandra/conf/cassandra.yaml"
  yaml = YAML::load_file(yaml_file)
  cluster_name_in_yaml = yaml['cluster_name']
  puts "cluster_name in #{yaml_file} is #{cluster_name_in_yaml}"
  puts "cluster_name in node config is #{cluster_name}"
  if cluster_name_in_yaml != 'Test Cluster' && cluster_name != cluster_name_in_yaml
    msg = "Expected cluster name is '#{cluster_name_in_yaml}' as per cassandra.yaml and so it should not be \"#{cluster_name}\" in node configuration."
    invalid_cluster = true
  end
end

invalid_cluster = invalid_cluster || cluster_name == nil || cluster_name.empty?

#Valid cluster name provided?
if invalid_cluster
  puts "***FAULT:FATAL=Invalid cluster name \"#{cluster_name}\". #{msg}"
  e = Exception.new("no backtrace")
  e.set_backtrace("")
  raise e
end

#higher version selected?
if actionName == 'update'
  selected_version = node.workorder.rfcCi.ciAttributes.version
  current_version = `/app/cassandra/current/bin/cassandra -v`
  puts "***RESULT:node_version=" + current_version
  puts "current_version = #{current_version}"
  puts "selected_version = #{selected_version}"
  Version_Change = Gem::Version.new(current_version) <=> Gem::Version.new(selected_version) 
  puts "Version_Change = #{Version_Change}"
  if Version_Change == 1
    message = "Version down grade is not supported."
    puts "***FAULT:FATAL=" + message
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
  elsif  Version_Change == -1
    Chef::Log.info("Upgrade detected. Exiting. Please run upgrade action at operations stage")
    exit 0
  end
end

dc_rack_map = JSON.parse(ci.ciAttributes.cloud_dc_rack_map)
#For new cluster map of Cloud to DC:Rack must be provided
if dc_rack_map.nil? || dc_rack_map.empty?
  if Cassandra::Util.new_cluster?(node)
    puts "***FAULT:FATAL=Map of Cloud to DC:Rack must be provided"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e         
  end
  dc_rack_map = Cassandra::Util.default_dc_rack_mapping(node)
end
node.default[:dc_rack_map] = dc_rack_map
	
if ci.ciAttributes.has_key?("auth_enabled") && ci.ciAttributes.auth_enabled.eql?("true")
	username = ci.ciAttributes.has_key?("username") ? ci.ciAttributes.username : ""
	password = ci.ciAttributes.has_key?("password") ? ci.ciAttributes.password : ""
	if username.empty? || password.empty?
	   puts "***FAULT:FATAL=Invalid username or password."
	   e = Exception.new("no backtrace")
	   e.set_backtrace("")
	   raise e         
	end
end

#TODO Check JVM version "Cassandra 3.0 and later require Java 8u40 or later"
#TODO Port checks from DSE on properties that should never be changed.
