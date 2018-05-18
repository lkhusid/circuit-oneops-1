#
# Cookbook Name :: solrcloud
# Recipe :: add.rb
#
# The recipe stops the solrcloud on the node.
#

include_recipe 'solrcloud::default'
extend SolrCloud::Util


if (node['skip_solrcloud_comp_execution'] == "true")
  # Refreshing the monitors when the compute is replaced in order to monitor the solrcloud in the new compute.
  # It has no impact when the computes are added.
  include_recipe 'solrcloud::monitor'
  Chef::Log.info("Skipping execution of solrcloud component. Since skip_solrcloud_comp_execution flag is enabled.")
  return
end

include_recipe 'solrcloud::solrcloud'
include_recipe 'solrcloud::deploy'
include_recipe 'solrcloud::customconfig'
include_recipe 'solrcloud::solrauth'

include_recipe 'solrcloud::monitor'
include_recipe 'solrcloud::post_solrcloud'

# Chef::Log.info("Configure Logging")
# template "/etc/logrotate.d/solr#{node['solrmajorversion']}" do
#   	source "solr.logrotate.erb"
#   	owner "#{node['solr']['user']}"
# 	group "#{node['solr']['user']}"
#     mode '0755'
# end

# cron "logrotate" do
#   	minute '0'
#   	command "sudo /usr/sbin/logrotate /etc/logrotate.d/solr#{node['solrmajorversion']}"
#   	mailto '/dev/null'
#   	action :create
# end


  