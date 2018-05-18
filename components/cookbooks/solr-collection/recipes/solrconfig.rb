#
# Cookbook Name :: solr-collection
# Recipe :: solrconfig.rb
#
# The recipe uses the solr config api and updates the solr-config.xml of the collection configuration.
#

include_recipe 'solr-collection::default'

extend SolrCollection::Util
# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)

args = ::JSON.parse(node.workorder.arglist)
property_type = args['property_type']
property_name = args['property_name']
property_value = args['property_value']

ci = node.workorder.ci.ciAttributes;
collection_name = ci['collection_name']
port_num = node['port_num']

if ( !"#{collection_name}".empty? ) && ( !"#{property_type}".empty? ) && ( !"#{property_name}".empty? ) && ( !"#{port_num}".empty? )
	validate_property_type(property_type)
	solr_config_api(node['ipaddress'], port_num, collection_name, property_type, property_name, property_value)
else
	raise "Required parameters (collection_name, property_type, property_name, port_num) are missing."
end

