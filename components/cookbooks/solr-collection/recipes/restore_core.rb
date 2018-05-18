include_recipe 'solr-collection::default'
extend SolrCollection::Util
extend SolrCloud::Util

# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)

# get solrcloud payload to determine the zookeeper fqdn
solrcloud_ci = node.workorder.payLoad.SolrCloudPayload[0].ciAttributes
setZkhostfqdn(solrcloud_ci['zk_select'], solrcloud_ci)

ci = node.workorder.has_key?("rfcCi")?node.workorder.rfcCi : node.workorder.ci

# get input arguments
args = ::JSON.parse(node.workorder.arglist)
collection_name = args["collection_name"]
backup_datetime = args["backup_datetime"]
  
# get backup_location from metedata attributes
backup_location = ci.ciAttributes.backup_location
if backup_location == nil || backup_location.empty?
  raise "Backup location must be provided."
end

# input collection name must match with the collection name from metedata attributes
if collection_name == nil || collection_name.empty?
  raise "Collection name must be provided."
end
if !collection_name.eql?node['collection_name']
  raise "Provided collection #{collection_name} is not configured on this component. The collection name associted with this collection component is #{node['collection_name']}"
end

# get backup_datetime to restore from backup name ends with backup_datetime
if backup_datetime == nil || backup_datetime.empty?
  raise "Backup time must be provided."
end

begin
  DateTime.strptime(backup_datetime,"%Y_%m_%d_%H_%M_%S" )
rescue Exception => msg
  raise "Unable to parse the input date & time #{backup_datetime} : #{msg}"
end

# upload_backup_config = true, meaning also upload/restore config from backup.
upload_backup_config = true
host = node['ipaddress']
port = node['port_num']
solr_version = node['solr_version']
zk_host_fqdns = node['zk_host_fqdns']
config_name = node['config_name']
current_zk_config_name = "current_#{node['config_name']}"

Chef::Log.info("collection_name = #{collection_name}")
Chef::Log.info("backup_datetime = #{backup_datetime}")
Chef::Log.info("backup_location = #{backup_location}")
Chef::Log.info("Solr host : #{host}")
Chef::Log.info("Solr port : #{port}")

# get all backup names starting with collection_name and ending with backup_datetime+-10 min
backup_names = get_backup_dirs("snapshot.#{collection_name}_", backup_location, backup_datetime)
Chef::Log.info("backup_names = #{backup_names.to_json}")
if backup_names.empty?
  Chef::Log.info("No backup found for collection #{collection_name} with timestamp #{backup_datetime}, hence no action")
  return
end
if backup_names.size > 1
  raise "Multiple backup found for collection #{collection_name} with timestamp #{backup_datetime}"
end
backup_name = backup_names[0]
Chef::Log.info("backup_name = #{backup_name}")

# download latest zookeeper config before restore
downloadDefaultConfig(solr_version, zk_host_fqdns, config_name, "#{backup_location}/#{current_zk_config_name}")

# get all backup configs starting with config_name and ending with backup_datetime+-10 min
backup_configs = get_backup_dirs(config_name, backup_location, backup_datetime)
Chef::Log.info("backup_configs : #{backup_configs.to_json}")
if backup_configs.empty?
  Chef::Log.info("No backup configs found with config name #{config_name} with timestamp #{backup_datetime}, hence no comparision will be done")
else 
  if backup_configs.size > 1
    raise "Multiple backup configs found with config name #{config_name} with timestamp #{backup_datetime}"
  else
    backup_config = backup_configs[0]
    # compare latest downloaded solrconfig.xml with backup. If upload_backup_config = true meaning, ignore any diff. as config will be restored from backup
    xml_diff("#{backup_location}/#{backup_config}/solrconfig.xml", "#{backup_location}/#{current_zk_config_name}/solrconfig.xml", !upload_backup_config)
    # compare latest downloaded managed-schema with backup. If upload_backup_config = true meaning, ignore any diff. as config will be restored from backup
    xml_diff("#{backup_location}/#{backup_config}/managed-schema", "#{backup_location}/#{current_zk_config_name}/managed-schema", !upload_backup_config)
    # restore/upload the config from backup
    if upload_backup_config == true
      uploadCustomConfig(solr_version, zk_host_fqdns, config_name, "#{backup_location}/#{backup_config}") 
    end
   end
end 

#snapshot.sams_list1_shard2_replica0_20171030_161724
core_name_excluding_collection = backup_name.split(collection_name+"_")
shard_name =  core_name_excluding_collection[1].split("_replica")[0]
Chef::Log.info("shard_name : #{shard_name}")

replicas = get_shard_core_ip_to_name_map(host,port,collection_name,shard_name)
Chef::Log.info("Existing replicas for shard #{shard_name} : #{replicas.to_json}")

delete_replica_on_this_node = false
#check if this node exists as a replica
if replicas.has_key?node['ipaddress']
  Chef::Log.info("This node #{node['ipaddress']} already exists as replica")
else
  delete_replica_on_this_node = true
end

#delete all replicas for shard
replicas.each do |node_ip,replica_name|
  params = {
    :collection => collection_name,
    :action => "DELETEREPLICA",
    :shard => shard_name,
    :replica => replica_name
  }
  Chef::Log.info("deleting replica => #{replica_name} node_ip=> #{node_ip} for shard=>#{shard_name} & collection => #{collection_name} using collection_api")
  collection_api(host, port, params, nil, "/solr/admin/collections")
end

# add only this replica as it has backup 
node_name = "#{node['ipaddress']}:#{port}_solr"
params = {
  :collection => collection_name,
  :action => "ADDREPLICA",
  :shard => shard_name,
  :node => node_name
}
Chef::Log.info("adding replica node => #{node_name} for shard=>#{shard_name} using collection_api")
collection_api(host, port, params, nil, "/solr/admin/collections")

#remove this node from replica map as it was already added
Chef::Log.info("Removing #{node['ipaddress']} as it is already added as leader")
replicas.delete(node['ipaddress'])

# verify that this node is the leader as restore will be done on this node/leader
shard_leader_ip_to_name_map = get_shard_leader_ip_to_name_map(host, port, collection_name, shard_name)
Chef::Log.info("shard_leader_ip_to_name_map = #{shard_leader_ip_to_name_map.to_json}")
if !shard_leader_ip_to_name_map.has_key?node['ipaddress']
  raise "#{node['ipaddress']} has the backup for shard #{shard_name} but it is not a leader"
else
  Chef::Log.info("#{node['ipaddress']} has the backup for shard #{shard_name} and also a leader")
end

#backups folders starts with 'snapshot.'
backup_name.sub! 'snapshot.', ''

#restore the core from selected backup  
restore(host, port, collection_name, shard_leader_ip_to_name_map[host], backup_location,backup_name)

#monitor the restore progress.
status = 'In Progress'
while ['In Progress'].include?status do
  status = get_core_backup_restore_status(host, port, shard_leader_ip_to_name_map[host], 'restorestatus')
  Chef::Log.info("status => #{status}")
  if status.eql?'failed'
    raise "restore failed"
  end
  # wait for 2 seconds
  sleep 2
end

#add all other replicas for this this shard number
replicas.each do |node_ip,replica_name|
  params = {
    :collection => collection_name,
    :action => "ADDREPLICA",
    :shard => shard_name,
    :replica => replica_name
  }
  Chef::Log.info("Adding replica => #{replica_name} node_ip=> #{node_ip} for shard=>#{shard_name} & collection => #{collection_name} using collection_api")
  collection_api(host, port, params, nil, "/solr/admin/collections")
end  

begin
  shards = get_shards_by_collection(host, port, collection_name)
  Chef::Log.info("shards for collection #{collection_name} : #{shards.to_json}")
  non_active_replicas = shards[shard_name]['replicas'].values.select { |replica| replica['state'] != 'active'}
  Chef::Log.info("non_active_replicas = #{non_active_replicas.to_json}")
  Chef::Log.info("Waiting for all replicas to be active..")
  sleep 5
end while !non_active_replicas.empty?

# If this node was not part of replica before restore then this needs to be deleted as it is an additional replica
if delete_replica_on_this_node == true
  
  # Wait for all nodes active
  shards = get_shards_by_collection(host,port,collection_name)
  
  replicas = get_shard_core_ip_to_name_map(host,port,collection_name,shard_name)
  Chef::Log.info("Existing replicas after restore for shard #{shard_name} : #{replicas.to_json}")
  replica_name = replicas[node['ipaddress']]
  params = {
     :collection => collection_name,
     :action => "DELETEREPLICA",
     :shard => shard_name,
     :replica => replica_name
  }
  Chef::Log.info("deleting replica => #{replica_name} for shard=>#{shard_name} & collection => #{collection_name} using collection_api")
  collection_api(host, port, params, nil, "/solr/admin/collections")
end

