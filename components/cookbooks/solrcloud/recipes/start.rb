#
# Cookbook Name :: solrcloud
# Recipe :: start.rb
#
# The recipe starts the solrcloud on the node.
#

include_recipe 'solrcloud::default'

ci = node.workorder.ci.ciAttributes;
solr_version = ci['solr_version']
solrmajorversion = "#{solr_version}"[0,1]

if "#{solr_version}".start_with? "4."
	if node['zk_host_fqdns'].empty?
    	raise "Zookeeper FQDN is missing in the pack.Provide the zookeeper infomation for the selected option"
  	end
	service "tomcat#{node['tomcatversion']}" do
    	provider Chef::Provider::Service::Init # for centos 7, provider should use system.d if required
    	supports :status => true, :restart => true, :start => true
    	action :start
	end
end

if ("#{solr_version}".start_with? "5.") || ("#{solr_version}".start_with? "6.") || ("#{solr_version}".start_with? "7.")
	if node['zk_host_fqdns'].empty?
    raise "Zookeeper FQDN is missing in the pack.Provide the zookeeper infomation for the selected option"
  end
	service "solr#{solrmajorversion}" do
    	provider Chef::Provider::Service::Init # for centos 7, provider should use system.d if required
    	supports :status => true, :restart => true, :start => true
    	action :start
	end
end

