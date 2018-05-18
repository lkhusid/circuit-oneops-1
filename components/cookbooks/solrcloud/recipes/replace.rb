#
# Cookbook Name :: solrcloud
# Recipe :: replace.rb
#
# The recipe sets up the solrcloud on the replaced node.
#
user_dir = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /User/ }.first[:ciAttributes]['username']
Chef::Log.info("user home directory : #{user_dir}")
deployment_status_file = "/opt/solr/deployment_status.txt"
# for 'replace' action if '/opt/solr/deployment_status.txt' exists means it's a old compute and hence skip the installation and replica adjustment logic
if ::File.exists?(deployment_status_file)
  Chef::Log.info("It seems no compute replace took place as there exists a file #{deployment_status_file} hence only solr process will be restarted.")
  include_recipe 'solrcloud::restart'
  include_recipe 'solrcloud::post_solrcloud'
  return
else
  Chef::Log.info("#{deployment_status_file} does not exists, hence solr be installed")
end
ci = node.workorder.rfcCi
attrs = ci[:ciAttributes]

# The attribute nodeip is populated in recipes/default.rb initially (while deploying a new solrcloud component for the first time).
# Then during replace-node, this attribute is persisted across the two runs (first-provision and replace-node).
# We make use of this persistence and save the nodeip attribute in another attribute called the old_node_ip.
# During replace-node, the nodeip attribute gets re-assigned to the current IP-address in default.rb again
# but by then, we have safely saved the older-IP in replace.rb at old_node_ip

if attrs.has_key?("nodeip") &&
    !attrs[:nodeip].empty?

  node.set["old_node_ip"] = node.workorder.rfcCi.ciAttributes.nodeip
  Chef::Log.info( " old_node_ip = #{node["old_node_ip"]}")

else
  Chef::Log.info( "node.workorder.rfcCi.ciAttributes.nodeip does not exist. Hence continuing normal replace of the node without adding the newly replaced node to its previous collections (if any)")
end

include_recipe 'solrcloud::default'

include_recipe 'solrcloud::solrcloud'
include_recipe 'solrcloud::deploy'
include_recipe 'solrcloud::customconfig'
include_recipe 'solrcloud::solrauth'



include_recipe 'solrcloud::replacenode'
include_recipe 'solrcloud::post_solrcloud'
include_recipe 'solrcloud::monitor'