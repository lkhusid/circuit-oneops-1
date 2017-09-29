include_recipe "secrets-client::set_attributes"

case node.provider 
when /keywhiz-cloud-service/
	include_recipe "keywhiz-client::add"
end
