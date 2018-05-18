#
# Cookbook Name :: solr-collection
# Recipe :: default.rb
#
# The recipe to wire all the ci and cookbook attribute to node object.
#

# This recipe is invoked both as part of the part of regular recipes as well as through OneOps Procedure/Actions
# The payload structure is different in either cases.
#

# get solrcloud payload to determine the solrcloud attrs
solrcloud_ci = node.workorder.payLoad.SolrCloudPayload[0].ciAttributes

begin
	# Check if we are invoked as part of the Procedure or Action
	if node.workorder.ci != nil
		ci = node.workorder.ci.ciAttributes;
		actionName = node.workorder.actionName
	end
rescue
ensure
end

oneops_action = true
begin
	# Check if we are invoked as part of the regular recipes add/update/delete
	if node.workorder.rfcCi != nil
		oneops_action = false
		ci = node.workorder.rfcCi.ciAttributes;
		actionName = node.workorder.rfcCi.rfcAction
	end
rescue
ensure
end

services = node[:workorder][:services]
# You must add solr-service at each cloud in order to access custom configurations
if services.nil?  || !services.has_key?('solr-service')
  Chef::Log.error('Please make sure your cloud has solr-service added.')
  exit 1
end
cloud_name = node[:workorder][:cloud][:ciName]
cloud_services = services['solr-service'][cloud_name]
node.default[:solr_custom_params] = JSON.parse(cloud_services[:ciAttributes][:solr_custom_params])
Chef::Log.info("solr_custom_params = #{node['solr_custom_params'].to_json}") 

node.set['action_name'] = actionName

node.set['collection_name'] = ci['collection_name']
node.set['num_shards'] = ci['num_shards']
node.set['replication_factor'] = ci['replication_factor']
node.set['max_shards_per_node'] = ci['max_shards_per_node']
# Getting port no from solrcloud component
node.set['port_num'] = solrcloud_ci['port_no']
node.set['config_name'] = ci['config_name']
node.set['allow_auto_reload_collection'] = ci['allow_auto_reload_collection']
node.set['autocommit_maxtime'] = ci['autocommit_maxtime']
node.set['autocommit_maxdocs'] = ci['autocommit_maxdocs']
node.set['autosoftcommit_maxtime'] = ci['autosoftcommit_maxtime']
node.set['updatelog_numrecordstokeep'] = ci['updatelog_numrecordstokeep']
node.set['updatelog_maxnumlogstokeep'] =  ci['updatelog_maxnumlogstokeep']
node.set['mergepolicyfactory_maxmergeatonce'] = ci['mergepolicyfactory_maxmergeatonce']
node.set['mergepolicyfactory_segmentspertier'] = ci['mergepolicyfactory_segmentspertier']
node.set['rambuffersizemb'] = ci['rambuffersizemb']
node.set['maxbuffereddocs'] = ci['maxbuffereddocs']
node.set['filtercache_size'] = ci['filtercache_size']
node.set['queryresultcache_size'] = ci['queryresultcache_size']
node.set['request_select_defaults_timeallowed'] = ci['request_select_defaults_timeallowed'] || "20000"
# node.set['documentcache_size'] = ci['documentcache_size']
# node.set['queryresultmaxdoccached'] = ci['queryresultmaxdoccached']

node.set['min_rf'] = ci['min_rf']

node.set['skip_collection_comp_execution'] = ci['skip_collection_comp_execution']
node.set['validation_enabled'] = ci['validation_enabled'] || "true"
node.set['collections_for_node_sharing'] = ci['collections_for_node_sharing']

#Search Custom Component Attributes
node.set['block_expensive_queries'] = ci['block_expensive_queries']
node.set['max_start_offset_for_expensive_queries'] = ci['max_start_offset']
node.set['max_rows_fetch_for_expensive_queries'] = ci['max_rows_fetch']

node.set['enable_slow_query_logger'] = ci['enable_slow_query_logger']
node.set['slow_query_threshold_millis'] = ci['slow_query_threshold_millis']

node.set['enable_query_source_tracker'] = ci['enable_query_source_tracker']
node.set['query_identifiers'] = ci['query_identifiers']
node.set['enable_fail_queries'] = ci['enable_fail_queries']

if ci.has_key?("zk_config_urlbase") && !ci[:zk_config_urlbase].empty?
  node.set['zk_config_urlbase'] = ci['zk_config_urlbase']
  if ci.has_key?("date_safety_check_for_config_update") && !ci[:date_safety_check_for_config_update].empty?
    node.set['date_safety_check_for_config_update'] = ci['date_safety_check_for_config_update']
  else
    Chef::Log.raise("Please provide today\'s date in YYYY-mm-DD format in UI to indicate that you do want to overwrite the ZK configuration.")
  end
else
  Chef::Log.info("User didn't provide any URL for ZK Config.")
end

if node.workorder.payLoad.has_key?("SolrCloudPayload") && !node.workorder.payLoad["SolrCloudPayload"].empty?
  solrcloud_ci = node.workorder.payLoad.SolrCloudPayload[0].ciAttributes
  node.set['solr_version'] = solrcloud_ci['solr_version']
  node.set['solrmajorversion'] = "#{node['solr_version']}"[0,1]
  node.set['user']['dir'] = "/app"
  node.set['solr']['user'] = "app"
  node.set['installation_dir_path'] = solrcloud_ci['installation_dir_path']
else
	error = "SolrCloudPayload payload not found, please pull the design"
	puts "***FAULT:FATAL= #{error}"
	raise error
end

=begin
	To execute the solr-collection component on one compute only we sort the list of computes in the payload and the
choose the first compute from the sorted list
	Steps:
	Sort the list of computes of the cluster
  Compare the current compute ciName with the first element in the sorted list of computes ciName
  If it is equal we run the solr-collection component on the compute else we skip the solr-collection component recipes
=end

is_solr_collection_running_on_this_node = "no"
node.set['skip_compute'] = 0

if oneops_action == false
	compute_name = ""
	if !node.workorder.payLoad.ManagedVia[0][:ciName].nil?
		compute_name = node.workorder.payLoad.ManagedVia[0][:ciName]
	else
		error = "node.workOrder.payload.ManagedVia[0][:ciName] is nil, we rely on this metadata to determine the compute on which the solr-collection component should run."
		puts "***FAULT:FATAL= #{error}"
		raise error
	end

	computes = node.workorder.payLoad.has_key?("RequiresComputes") ? node.workorder.payLoad.RequiresComputes : node.workorder.payLoad.computes

	if !computes.nil? && computes.length > 0
		sorted_computes = computes.sort_by { |c| c.ciName}
		first_compute = sorted_computes[0]
		first_compute_ciname = first_compute[:ciName]
		if (compute_name == first_compute_ciname)
                       is_solr_collection_running_on_this_node = "yes"
			Chef::Log.info("Solr-collection component will RUN on compute: #{compute_name}")
		else
			node.set['skip_compute'] = 1
			Chef::Log.info("Solr-collection component will NOT RUN on compute: #{compute_name}")
		end
	else
		error = "****FATAL ERROR*******: The Solr cluster does not have any computes passed in the payload"
		puts "***FAULT:FATAL=#{error}"
		raise error
	end
end

nodeip = "#{node['ipaddress']}"

# To set the ip,port and version for each solrcloud component
Chef::Log.info(" Node IP = " + nodeip + "is solr collection running on this node? " + is_solr_collection_running_on_this_node)
puts "***RESULT:nodeip="+nodeip
puts "***RESULT:first_compute_after_sort="+is_solr_collection_running_on_this_node








