#
# Cookbook Name :: solrcloud
# Recipe :: medusametrics.rb
#
# The recipe creates CORE_LIST,COLLECTION_LIST oneops environment variables.
#

require 'open-uri'
require 'json'
require 'uri'

include_recipe 'solrcloud::default'

extend SolrCloud::Util
# Wire SolrCloud util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

args = ::JSON.parse(node.workorder.arglist)
collections = args["collections"]

is_collection_exist = false
final_collections = []
cluster_collections = get_cluster_collections
if not cluster_collections.empty?
	if not "#{collections}".empty?
		collection_list = collections.split(',')
		collection_list.each do |collection|
			is_collection_exist = cluster_collections.include?(collection)
			if is_collection_exist
				final_collections.push collection
			end
		end
	else
		cluster_collections.each do |collection|
			final_collections.push collection
		end
	end
else
	Chef::Log.error("Collections are not created yet.")
end


# The /etc/profile.d/oneops.sh file contains environment variables which is used by telegraf template to execute the macro code.
Chef::Log.info("The resource sets collection names to the variable 'COLLECTION_LIST'")
bash 'set_collection_env' do
	code <<-EOH
		sed -i '/COLLECTION_LIST/d' /etc/profile.d/oneops.sh
		echo 'export COLLECTION_LIST=#{final_collections.join(',')}' >> /etc/profile.d/oneops.sh
	EOH
end

final_cores = []
core_list = get_node_solr_cores
core_list.each do |core|
	final_collections.each do |collection|
		if core.include?("#{collection}_shard")
			final_cores.push core
		end
	end
end

# The /etc/profile.d/oneops.sh file contains environment variables which is used by telegraf template to execute the macro code.
Chef::Log.info("The resource sets core names to the variable 'CORE_LIST'")
bash 'set_core_env' do
	code <<-EOH
		sed -i '/CORE_LIST/d' /etc/profile.d/oneops.sh
		echo 'export CORE_LIST=#{final_cores.join(',')}' >> /etc/profile.d/oneops.sh
	EOH
end

