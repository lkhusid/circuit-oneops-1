require 'net/http'
require 'json'

include_recipe 'solr-collection::default'

if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi.ciAttributes
else
  ci = node.workorder.ci.ciAttributes
end
args = ::JSON.parse(node.workorder.arglist)
collection_name = args["collection_name"]
Chef::Log.info("collection_name = #{collection_name}")

if collection_name == nil || collection_name.empty?
  raise "Collection name must be provided."
end

if !collection_name.eql?node['collection_name']
  raise "Provided collection #{collection_name} is not configured on this component. The collection name associted with this collection component is #{node['collection_name']}"
end

backup_restore = args["backup_or_restore"]
if backup_restore == nil || backup_restore.empty?
  backup_restore = "Backup"
end
Chef::Log.info("backup_restore = #{backup_restore}")
backup_restore_option = backup_restore.strip.downcase
options = ["backup","restore"]
if !options.include?backup_restore_option
  raise "Invalid backup_restore option is provided. Valid options are : #{options.to_json}"
end

command = "restorestatus"
if backup_restore.strip.downcase == 'backup'
  command = "details"
end
def get_core_backup_restore_status(host,port,core_name,command)
  uri = URI("http://#{host}:#{port}/solr/#{core_name}/replication?command=#{command}&wt=json")
  Chef::Log.info("Backup/Restore url : #{uri}")
  res = Net::HTTP.get_response(uri)
  if !res.is_a?(Net::HTTPSuccess)
    msg = "Error while getting core backup/restore status : #{res.message}"
    raise msg
  else
    Chef::Log.info("backup/restore response : #{res.body}")
  end
end

def get_cores_backup_restore_status(host,port,collection_name, command)
  uri = URI("http://#{host}:#{port}/solr/admin/collections?action=CLUSTERSTATUS&indexInfo=false&wt=json")
  res = Net::HTTP.get_response(uri)
  if !res.is_a?(Net::HTTPSuccess)
    msg = "Error while reading clusterstate : #{res.message}"
    raise msg
  else
    Chef::Log.info("cluster status response : #{res.body}")
  end

  data =  JSON.parse(res.body)
  collections =  data['cluster']['collections']
  if collections.empty? || !collections.has_key?(collection_name)
    msg = "No collection found : #{collection_name}"
    raise msg
  end

  shards =  collections[collection_name]['shards']
  Chef::Log.info("Shards found : #{shards.to_json}")

  core_name_to_node_name_map = Hash.new()
  shards.values.each do |shard|
    replicas = shard['replicas']
      replica_map = JSON.parse(replicas.to_json )
      replica_map.each do |key,value|
          core_name = value['core']
          node_name = value['node_name']
          core_name_to_node_name_map[core_name] = node_name
      end
  end
 
  if core_name_to_node_name_map.empty?
    raise "No cores found"
  end
  
  core_name_to_node_name_map.each do |core_name,node_name|
    Chef::Log.info("Core/Node name : #{core_name}/#{node_name}")
    Chef::Log.info("Getting backup status for core #{core_name} at node #{node_name}")
    get_core_backup_restore_status(host, port, core_name, command)
  end

end

solr_host = node['ipaddress']
solr_port = node['port_num']

Chef::Log.info("Collection : #{collection_name}")
Chef::Log.info("Solr host : #{solr_host}")
Chef::Log.info("Solr port : #{solr_port}")
get_cores_backup_restore_status(solr_host,solr_port,collection_name, command)

