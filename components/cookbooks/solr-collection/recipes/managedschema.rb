#
# Cookbook Name :: solr-collection
# Recipe :: managedschema.rb
#
# The recipe is to add/update/delete (different schema action )the fields (or various tags) in manage-schema configuration file.
#

include_recipe 'solr-collection::default'

extend SolrCollection::Util
# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)

args = ::JSON.parse(node.workorder.arglist)
schema_action = args['schema_action']
json_payload = args['json_payload']
field_payload = ::JSON.parse(json_payload)
update_timeout_secs = args['update_timeout_secs']

ci = node.workorder.ci.ciAttributes;
collection_name = ci['collection_name']
port_num = node['port_num']

if ( !"#{collection_name}".empty? ) && ( !"#{schema_action}".empty? ) && ( !"#{json_payload}".empty? ) && ( !"#{port_num}".empty? )
  validate_schema_action(schema_action)
  parseJSON(json_payload)
  if schema_action.eql?("add-field")
    field_exists = field_type_exists(node['ipaddress'], port_num, collection_name, field_payload['name'], field_payload['type'])
    if field_exists
        Chef::Log.info("Field #{field_payload['name']} already exists")
        return
    end
  end
  manage_schema_api(node['ipaddress'], port_num, collection_name, schema_action, json_payload, update_timeout_secs)
else
  raise "Required parameters (collection_name, schema_action, json_payload, port_num) are missing."
end

