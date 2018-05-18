#
# Cookbook Name :: solrcloud
# Recipe :: replacenode.rb
#
# The recipe adds the replaced node to the shard with the fewest replicas, tie-breaking on the lowest shard number.
#

extend SolrCloud::Util

# Wire solrcloud util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

# Add the new replaced node to the solr cluster without affecting the cluster status
ruby_block "replace_node" do
  block do
    if node.has_key?("old_node_ip") && !node["old_node_ip"].empty?
      Chef::Log.info("The compute IP address changed from Old IP #{node["old_node_ip"]} to #{node['ipaddress']}, will start with retain_replicas_on_node option.")
      retain_replicas_on_node(node["old_node_ip"])
    end
  end
end



# ############################################################################################################

# Un-used logic in replace

ci = node.workorder.rfcCi.ciAttributes;

join_replace_node = ci['join_replace_node']
collection_list = ci['collection_list']

if (join_replace_node == 'true')

  ruby_block 'join_replaced_node' do
    block do

      cnames = collection_list.split(",")

      if (node['solr_version'].start_with? "4.")
        request_url = "http://#{node['ipaddress']}:8080/"+"#{node['clusterstatus']['uri']}"
        Chef::Log.info("#{request_url}")
        response = open(request_url).read
        jsonresponse = JSON.parse(response)

        aliasList = jsonresponse["cluster"]["aliases"];
        if !"#{aliasList}".empty?
          aliasList = aliasList.keys
        end

        cnames.each do |cname|
          if (!aliasList.empty?) && (aliasList.include? "#{cname}")
            collection_name = jsonresponse["cluster"]["aliases"]["#{cname}"]
          else
            collection_name = cname
          end

          maxShardsPerNode = jsonresponse["cluster"]["collections"]["#{collection_name}"]["maxShardsPerNode"]
          shardList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"].keys
          time = Time.now.getutc.to_i
          shardToReplicaCountMap = Hash.new()

          # Create a map with shard name and replica count and sort by name and count.
          shardList.each do |shard|
            shardstate = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["state"]
            if shardstate == "active"
              replicaList = jsonresponse["cluster"]["collections"]["#{collection_name}"]["shards"][shard]["replicas"].keys
              shardToReplicaCountMap[shard] = replicaList.size
            end
          end
          shardToReplicaCountMap = shardToReplicaCountMap.sort_by { |name, count| count }

          # Repeat the below step based on the maxShardsPerNode value and add the node as a replica.
          # Select the first shard from the map which has lowest no of replicas.
          for i in 1..Integer(maxShardsPerNode)
            shard = shardToReplicaCountMap[i - 1][0]
            begin
              addreplica_url = "#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard}&node=#{node['ipaddress']}:8080_solr"
              Chef::Log.info(addreplica_url)
              addreplica_response = open(addreplica_url).read
            rescue
              Chef::Log.error("Failed to add replica to the collection '#{collection_name}'. Collection '#{collection_name}' may not exists.")
            ensure
              puts "End of join_node execution."
            end
          end
        end
      end

      if (node['solr_version'].start_with? "5.") || (node['solr_version'].start_with? "6.") || (node['solr_version'].start_with? "7.")

        request_url = "http://#{node['ipaddress']}:#{node['port_no']}/"+"#{node['aliases_uri_v6']}"
        Chef::Log.info("#{request_url}")
        response = open(request_url).read
        jsonresponse = JSON.parse(response)

        aliasMap = JSON.parse(jsonresponse["znode"]["data"])
        if !"#{aliasMap}".empty?
          collaliasList = aliasMap["collection"].keys
        end

        cnames.each do |cname|
          if (!collaliasList.empty?) && (collaliasList.include? "#{cname}")
            collection_name = jsonresponse["cluster"]["aliases"]["#{cname}"]
          else
            collection_name = cname
          end

          request_url = "http://#{node['ipaddress']}:#{node['port_no']}/#{node['clusterstatus']['uri_v6']}/#{collection_name}/state.json"
          Chef::Log.info("#{request_url}")
          response = open(request_url).read
          jsonresponse = JSON.parse(response)

          coll_hash = JSON.parse(jsonresponse["znode"]["data"])
          res = coll_hash["#{collection_name}"]
          maxShardsPerNode = res["maxShardsPerNode"]
          shardList = res["shards"].keys
          shardToReplicaCountMap = Hash.new()

          # Create a map with shard name and replica count and sort by name and count.
          shardList.each do |shard|
            shardstate = res["shards"][shard]["state"]
            if shardstate == "active"
              replicaList = res["shards"][shard]["replicas"].keys
              shardToReplicaCountMap[shard] = replicaList.size
            end
          end

          shardToReplicaCountMap = shardToReplicaCountMap.sort_by { |name, count| count }

          # Repeat the below step based on the maxShardsPerNode value and add the node as a replica.
          # Select the first shard from the map which has lowest no of replicas.
          for i in 1..Integer(maxShardsPerNode)
            shard = shardToReplicaCountMap[i - 1][0]
            begin
              addreplica_url = "#{node['solr_collection_url']}?action=ADDREPLICA&collection=#{collection_name}&shard=#{shard}&node=#{node['ipaddress']}:#{node['port_no']}_solr"
              Chef::Log.info(addreplica_url)
              addreplica_response = open(addreplica_url).read
            rescue
              raise "Failed to add replica to the collection '#{collection_name}'. Collection '#{collection_name}' may not exists."
            ensure
              puts "End of join_node execution."
            end
          end

        end
      end

    end
  end

end




