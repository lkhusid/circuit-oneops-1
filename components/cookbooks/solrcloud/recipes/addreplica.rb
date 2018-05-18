#
# Cookbook Name :: solrcloud
# Recipe :: addreplica.rb
#
# The recipe adds replica to the solr cloud.
#

require 'json'
require 'excon'

include_recipe 'solrcloud::default'

extend SolrCloud::Util
# Wire SolrCloud util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

args = ::JSON.parse(node.workorder.arglist)
collection_name = args["PhysicalCollectionName"]
shard_name = args["ShardName"]
time = Time.now.getutc.to_i

downreplicalist = []

if (!"#{collection_name}".empty?) && (!"#{shard_name}".empty?)
    cluster_collections = get_cluster_collections
    is_collection_exist = cluster_collections.include?(collection_name)
    if not is_collection_exist
        Chef::Log.raise("Collection does not exists.")
    end
    validateShardName("#{shard_name}")


        params = {:action => "CLUSTERSTATUS"}
        jsonresponse = solr_collection_api(node['ipaddress'],node['port_no'],params)

        res = jsonresponse["cluster"]["collections"][collection_name]


        maxShardsPerNode = res["maxShardsPerNode"]
        replicationFactor = res["replicationFactor"]
        shardList = res["shards"].keys

        numShardExists = 0
        noofoccurrences = 0
        shardList.each do |shard|
            shardstate = res["shards"][shard]["state"]
            if shardstate == "active"

                replicaList = res["shards"][shard]["replicas"].keys
                replicaList.each do |replica|
                    replicastate = res["shards"][shard]["replicas"][replica]["state"]
                    node_name = res["shards"][shard]["replicas"][replica]["node_name"]
                    replicaip = node_name[0,node_name.index(':')]
                    downreplicalist.push(replicaip) if replicastate == "down"
                    if (replicaip == "#{node['ipaddress']}")
                        numShardExists = numShardExists + 1 if noofoccurrences == 0
                        noofoccurrences = noofoccurrences + 1
                        if (shard == shard_name)
                            if (Integer(noofoccurrences) == Integer(maxShardsPerNode))
                                Chef::Log.error("Node #{replicaip} reached max no of shards.")
                                return
                            else
                                Chef::Log.error("Node #{replicaip} is already added as replica to #{shard_name}. Please choose another instance.")
                                return
                            end
                        end
                    end
                end
            end
        end

        # If the choosed node is running and doesn't reach maxShardsPerNode then adds as a replica to the shard.
        if numShardExists < Integer(maxShardsPerNode)
            if (downreplicalist.include? "#{node['ipaddress']}")
                return
            else
                addReplica(shard_name,collection_name)
            end
        else
          puts "Maximum shards per node is reached, cannot add replica"
        end

else
    Chef::Log.raise("Required input parameters (collection_name,shard_name) are not provided.")
end

