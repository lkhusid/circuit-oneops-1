#
# Cookbook Name :: solr-collection
# Recipe :: reload_collection.rb
#
# The recipe reloads the collection.
#

require 'open-uri'
require 'json'
require 'uri'

include_recipe 'solr-collection::default'

extend SolrCollection::Util
# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)

args = ::JSON.parse(node.workorder.arglist)

# The collection or core name which user gives for re-load action to perform
collection_name = args["collection_name"]

ci = node.workorder.ci.ciAttributes;
# The collection name which is associated with this solr-collection instance
component_collection_name = ci['collection_name']
port_num = node['port_num']

Chef::Log.info("Component Collection name : #{component_collection_name}")

if ( collection_name != nil && !collection_name.empty? && (component_collection_name == collection_name) )
  run_reload_collection(collection_name, port_num)
else
  raise "Provided collection #{collection_name} is not configured on this component. The collection name associted with this collection component is #{component_collection_name}"
end

