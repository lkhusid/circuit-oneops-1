extend SolrCollection::Util
require "#{File.dirname(__FILE__)}/replica_distributor"
require 'json'

# For the given shard, add a replica to the given IP
def add_replica (collection_name, shard_num, ip, port_num)
    shard_name = "shard"+"#{shard_num}"
    node_name = "#{ip}:#{port_num}_solr"
    Chef::Log.info("Adding replica for #{shard_name} to #{node_name}")
    params = {
        :action => "ADDREPLICA",
        :collection => collection_name,
        :shard => shard_name,
        :node => node_name
    }
    response = collection_api(ip, port_num.to_s, params)
    Chef::Log.info("#{response.to_json}")
    return true
end

# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)

Chef::Log.info("*** Placing replicas for #{node['collection_name']} ***")

collections_for_node_sharing = JSON.parse(node['collections_for_node_sharing'])
collections_for_node_sharing.collect! {|collection_name| collection_name.strip }
collections_for_node_sharing = collections_for_node_sharing.reject {|coll| coll == node['collection_name'] || coll == 'NO_OP_BY_DEFAULT'}
ipaddress = node['ipaddress']
port_num = node['port_num'].to_i

existing_cluster_collections = get_collections(ipaddress, port_num.to_s)
cloud_provider = CloudProvider.get_cloud_provider_name(node)
computes = CloudProvider.get_computes_payload(node)

replicaDistributor = ReplicaDistributor.new
Chef::Log.info("existing_cluster_collections = #{existing_cluster_collections.to_json}")
shard_num_to_iplist_map = replicaDistributor.get_shard_number_to_core_ips_map(node['num_shards'].to_i, node['replication_factor'].to_i, computes, cloud_provider, collections_for_node_sharing, existing_cluster_collections)

Chef::Log.info("shard_num_to_iplist_map = #{shard_num_to_iplist_map.to_json}")
shard_num_to_iplist_map.each do |shard_num, ip_list|
  ip_list.each do |ip|
    add_replica(node['collection_name'], shard_num, ip, port_num.to_s)
  end
end