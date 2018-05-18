#
# Cookbook Name :: solr-collection
# Recipe :: clusterstate.rb
#
# The recipe removes dead replicas and update the clusterstate in zookeeper.
#

require 'open-uri'
require 'json'
require 'uri'

include_recipe 'solr-collection::default'

extend SolrCollection::Util
# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["collection_name"]

ci = node.workorder.ci.ciAttributes;
component_collection_name = ci['collection_name']
port_num = node['port_num']

if ( collection_name != nil && !collection_name.empty? && (component_collection_name == collection_name) )
    params = {
        :action => "CLUSTERSTATUS"
    }
    live_nodes = get_cluster_livenodes(port_num)
    collectionstate_resp = get_collection_state(node['ipaddress'], port_num, component_collection_name, params)
    shard_list = collectionstate_resp["shards"].keys
    shards = collectionstate_resp["shards"]

    shard_list.each do |shard|
        shard_state = collectionstate_resp["shards"][shard]["state"]
        if shard_state == "active"
            replica_list = collectionstate_resp["shards"][shard]["replicas"].keys
            replica_list.each do |replica|
                replica_state = collectionstate_resp["shards"][shard]["replicas"][replica]["state"]
                replica_node_name = collectionstate_resp["shards"][shard]["replicas"][replica]["node_name"]
                replica_ip = replica_node_name.split(':')
                is_live_node = live_nodes.include?(replica_ip)
                if replica_state == "down" && !is_live_node
                    params = {
                        :action => "DELETEREPLICA",
                        :collection => collection_name,
                        :shard => shard,
                        :replica => replica
                    }
                    collection_api(node['ipaddress'], port_num, params)
                end
            end
        end
    end
else
    raise "Provided collection is not configured on this component."
end

