#
# Cookbook Name :: solr-collection
# Recipe :: collection.rb
#
# The recipe create and modify collection on solr cluster.
#

include_recipe 'solr-collection::default'

extend SolrCollection::Util
# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)


collection_name = node['collection_name']
num_shards = node['num_shards']
replication_factor = node['replication_factor']
max_shards_per_node = node['max_shards_per_node']
config_name = node['config_name']
port_num = node['port_num']



if !collection_name || collection_name.empty? then
    Chef::Log.raise("Required parameter: \"collection_name\" is missing")
end
if !replication_factor || replication_factor.empty? then
    Chef::Log.raise("Required parameter: \"replication_factor\" is missing")
end
if !max_shards_per_node || max_shards_per_node.empty? then
    Chef::Log.raise("Required parameter: \"max_shards_per_node\" is missing")
end
if "#{config_name}".empty? || "#{num_shards}".empty? then
    Chef::Log.raise("Required parameters \"config_name\" or \"num_shards\" are missing.")
end



ruby_block 'create_collection' do
    block do
        # Find out if the collection already exists and how many replicas it has
        replica_count = 0
        collection_exists = false
        params = {
            :action => "CLUSTERSTATUS"
        }
        cluster_status_resp = collection_api(node['ipaddress'], port_num, params)
        cluster_collections = cluster_status_resp["cluster"]["collections"]
        if !cluster_collections.empty? && cluster_collections[collection_name]
            Chef::Log.info("Collection exists: #{cluster_collections[collection_name].to_json}")
            collection_exists = true
            collection_state_obj = cluster_collections[collection_name]
            shards = collection_state_obj["shards"]
            shards.each { |shard_name, shard_info|
                replicas = shard_info["replicas"]
                replica_count += replicas.size
            }
        end
        Chef::Log.info("replica_count: #{replica_count}")


        if !collection_exists || replica_count == 0
            # Collection creation is obvious if it does not exist
            # But even if it exists, we try to add replicas for it if it does not have any replicas.
            # This is so because a collection without replicas is useless and most likely an artifact
            # of a previous failure while adding replicas
            live_nodes = get_cluster_livenodes(port_num)
            total_cores_required = num_shards.to_i * replication_factor.to_i
            max_shards_per_node_required = (total_cores_required.to_f / live_nodes.size).ceil
            if max_shards_per_node_required > max_shards_per_node.to_i
                available_cores = max_shards_per_node.to_i * live_nodes.size
                error_msg = "Cannot create collection #{collection_name} with provided configuration."+
                "num_shards = #{num_shards}, replication_factor = #{replication_factor}, max_shards_per_node = #{max_shards_per_node} " +
                "because total_cores_required = #{total_cores_required} and available_cores are only #{available_cores}"
                Chef::Log.raise(error_msg)
            else
                ##############################################################################
                # Warn against multiple replicas of same shard on a single node. For example:
                # Consider an 8 node cluster and a collection request for shards = 2,
                # replication factor = 12 and maxShardsPerNode = 3
                #
                # For the above case, 12 replicas need to be placed on 8 nodes.
                # And we will end up placing multiple replicas of the same shard on a single
                # node. This placement does not seem very useful and it is good to warn
                ##############################################################################
                if replication_factor.to_i > live_nodes.size
                    error_msg = "When the replication_factor is greater than total no of nodes " +
                    "then for every shard, it creates multiple replicas on every node. This is " +
                    "not very useful and should be avoided."
                    Chef::Log.warn(error_msg)
                end
                if (!collection_exists) then
                    params = {
                        :action => "CREATE",
                        :name => collection_name,
                        :numShards => num_shards,
                        :replicationFactor => replication_factor,
                        :maxShardsPerNode => max_shards_per_node,
                        :createNodeSet => ''
                    }
                    collection_api(node['ipaddress'], port_num, params, config_name)
                end
                run_context.include_recipe 'solr-collection::add_replica'
            end
        else
            coll_max_shards_per_node = collection_state_obj["maxShardsPerNode"]
            coll_replication_factor = collection_state_obj["replicationFactor"]

            msg = "replication_factor" +
                  "(old:#{coll_replication_factor}, new:#{replication_factor}) and " +
                  "max_shards_per_node" +
                  "(old:#{coll_max_shards_per_node}, new:#{max_shards_per_node})"
            Chef::Log.info(msg)
            if ((replication_factor != coll_replication_factor) || (max_shards_per_node != coll_max_shards_per_node))
                Chef::Log.info("Executing MODIFYCOLLECTION due to change in replication_factor or max_shards_per_node")
                params = {
                    :action => "MODIFYCOLLECTION",
                    :collection => collection_name,
                    :replicationFactor => replication_factor,
                    :maxShardsPerNode => max_shards_per_node
                }
                collection_api(node['ipaddress'], port_num, params)
            else
                Chef::Log.info("Attributes (replication_factor & max_shards_per_node) have not changed, skipping MODIFYCOLLECTION.")
            end
        end
    end
end # create_collection




ruby_block 'override_collection_config' do
  block do

    remove_overridden_props = Array.new
    new_overridden_props = Hash.new

    autocommit_maxTime_prop = "autocommit_maxtime"
    autocommit_maxDocs_prop = "autocommit_maxdocs"
    autoSoftCommit_maxTime_prop = "autosoftcommit_maxtime"
    filterCache_size_prop = "filtercache_size"
    queryResultCache_size_prop = "queryresultcache_size"
    queryDocCache_size_prop = "documentcache_size"
    queryResultMaxDocCached_prop = "queryresultmaxdoccached"


    if node[autocommit_maxTime_prop].nil?
      remove_overridden_props.push("updateHandler.autoCommit.maxTime")
    else
      new_overridden_props["updateHandler.autoCommit.maxTime"] = node[autocommit_maxTime_prop]
    end

    if node[autocommit_maxDocs_prop].nil?
        remove_overridden_props.push("updateHandler.autoCommit.maxDocs")
    else
        new_overridden_props["updateHandler.autoCommit.maxDocs"] = node[autocommit_maxDocs_prop]
    end

    if node[autoSoftCommit_maxTime_prop].nil?
        remove_overridden_props.push("updateHandler.autoSoftCommit.maxTime")
    else
        new_overridden_props["updateHandler.autoSoftCommit.maxTime"] = node[autoSoftCommit_maxTime_prop]
    end

    if node[filterCache_size_prop].nil?
        remove_overridden_props.push("query.filterCache.size")
    else
        new_overridden_props["query.filterCache.size"] = node[filterCache_size_prop]
    end

    if node[queryResultCache_size_prop].nil?
        remove_overridden_props.push("query.queryResultCache.size")
    else
        new_overridden_props["query.queryResultCache.size"] = node[queryResultCache_size_prop]
    end

    # if node[queryDocCache_size_prop].nil?
    #     remove_overridden_props.push("query.DocumentCache.size")
    # else
    #     new_overridden_props["query.DocumentCache.size"] = node[queryDocCache_size_prop]
    # end
    #
    # if node[queryResultMaxDocCached_prop].nil?
    #   remove_overridden_props.push("query.queryResultMaxDocCached")
    # else
    #   new_overridden_props["query.queryResultMaxDocCached"] = node[queryResultMaxDocCached_prop]
    # end

    Chef::Log.info("Properties configured in SolrCollection component #{new_overridden_props}")

    Chef::Log.info("Existing Overridden Properties that need to be removed or unset: #{remove_overridden_props}")

    # get existing Configuration properties which are overridden in configoverlay.json from Solr using the REST API
    Chef::Log.info("Getting Solr configuration from config/overlay REST Endpoint")

    existing_props = get_props_from_configoverlay_json(node[:ipaddress], port_num, collection_name)

    Chef::Log.info("Existing Properties downloaded from configoverlay.json: #{existing_props}")
    # get the configuration properties which have been changed as part of this deployment, we do a diff between
    # new_overridden_props and existing_props
    new_overridden_props = get_properties_changed(new_overridden_props, existing_props)

    Chef::Log.info("Properties changed as part of this deployment, which needs to be set to configoverlay.json: #{new_overridden_props}")

    # Now the new_overridden_props has only the config properties which have been changed in this deployment

    # These need to be set in the configoverlay.json file in the Zookeeper using the Solr config REST API
    override_solrconfig_properties(node[:ipaddress], port_num, collection_name, new_overridden_props)

    # Remove the overidden properties which have been unset as part of this deployment
    remove_overridden_solrconfig_properties(node['ipaddress'], port_num, collection_name, remove_overridden_props)

  end
end # override_collection_config




# ruby_block 'ignore_commit_optimize_requests_enabled' do
#   block do
#     if node['validation_enabled'] == 'true' && !ignore_commit_optimize_requests_enabled?
#       error = "IgnoreCommitOptimizeUpdateProcessorFactory is not found in one of the UpdateRequestProcessorChains.This processor is very highly recommended so that no one can issue commits or optimize calls very frequently and destabilize the cluster. If you still believe you do not need this validation-failure, please disable the validation flag from collection component."
#       puts "***FAULT:FATAL=#{error}"
#       raise error
#     end
#   end   
# end

# Verify if schemaless mode is disabled in order to avoid users to rapidly construct effective schema without manually modifying the schema.
ruby_block 'disallow_schemaless_mode' do
  block do
    if node['validation_enabled'] == 'true' && schemaless_mode_enabled
        error = "Schemaless mode is found enabled in the config and it is not recommended for use.
        In the schemaless mode, Solr will guess the field-type to the most basic type which may be very inefficient.
        For example, it will not attempt tokenization on string fields and it will not set docValues=true for fields requiring sorting, faceting or pivoting etc.
        Hence this mode is prohibited for production use. If you still want to use it, disable the validation checkbox in the collection component."
        puts "***FAULT:FATAL=#{error}"
        raise error
    end
  end
end
