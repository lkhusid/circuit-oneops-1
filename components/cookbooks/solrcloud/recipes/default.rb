#
# Cookbook Name :: solrcloud
# Recipe :: default.rb
#
# The recipe sets the variable.
#

extend SolrCloud::Util

# Wire SolrCloud Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)
cloud_name = node[:workorder][:cloud][:ciName]
mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
services = node[:workorder][:services]
# You must add solr-service at each cloud in order to access custom configurations
if services.nil?  || !services.has_key?('solr-service')
  Chef::Log.error('Please make sure your cloud has solr-service added.')
  exit 1
end

cloud_services = services['solr-service'][cloud_name]
node.default[:solr_custom_params] = JSON.parse(cloud_services[:ciAttributes][:solr_custom_params])
Chef::Log.info("solr_custom_params = #{node['solr_custom_params'].to_json}") 

oneops_action = true
if node.workorder.has_key?("rfcCi")
  oneops_action = false
  ci = node.workorder.rfcCi.ciAttributes;
  actionName = node.workorder.rfcCi.rfcAction
else
  ci = node.workorder.ci.ciAttributes;
  actionName = node.workorder.actionName
end

node.set['solr']['user'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /User/ }.first[:ciAttributes]['username']
node.set['user']['dir'] = "/"+node['solr']['user']

result = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }

if(result.any?)
  node.set['tomcat_version'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['version']
  node.set['protocol'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['protocol']
  node.set['executor_name'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['executor_name']
  node.set['enable_method_trace'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['enable_method_trace']
  node.set['server_header_attribute'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['server_header_attribute']
  node.set['ssl_port'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['ssl_port']
  node.set['advanced_connector_config'] = node.workorder.payLoad.DependsOn.select {|c| c[:ciClassName] =~ /Tomcat/ }.first[:ciAttributes]['advanced_connector_config']
  node.set['tomcatversion'] = node['tomcat_version'][0,1];
  node.set['tomcat']['dir'] = node['user']['dir']+"/tomcat"+node['tomcatversion']
end

# As per the current design, user can have 3 volume components.
# 1. volume -app
# 2. volume-blockstorage
# 3. volume
# volume-blockstorage and volume has cardinality 0-1 and volume-app has exactly one.
# User can never have 2 CINDER volume components, since it depends on Storage component which has 0-1 as the cardinality.
# User can have 2 ephemeral volume components and both of them doesn't depend on solrcloud.
volume_blockstorage_list = node.workorder.payLoad.DependsOn.select {|c| c['ciName'] =~ /volume-blockstorage/ }
volume_app_list = node.workorder.payLoad.DependsOn.select {|c| c['ciName'] =~ /volume-app/ }

if (volume_blockstorage_list.any?)
  Chef::Log.info("Cinder storage is enabled for solrcloud!")
  node.set['cinder_volume_mountpoint'] = volume_blockstorage_list.first[:ciAttributes]['mount_point']
else
  Chef::Log.info("Cinder is not enabled. Solrcloud is mounted on Ephemeral.")
end
volume_app_mount_point = ""
if volume_app_list.any?
  volume_app_mount_point = volume_app_list.first[:ciAttributes]['mount_point']
end
node.set['action_name'] = actionName

node.set['jmx_port'] = ci['jmx_port']

node.set["zk_select"] = ci['zk_select']
node.set["num_instances"] = ci['num_instances']
node.set["port_num_list"] = ci['port_num_list']
node.set["platform_name"] = ci['platform_name']
node.set["env_name"] = ci['env_name']
node.set['solrcloud']['cloud_ring'] = ci['cloud_ring']
node.set['solrcloud']['datacenter_ring'] = ci['datacenter_ring']
node.set['solrcloud']['replace_nodes'] = ci['replace_nodes']

node.set['skip_solrcloud_comp_execution'] = ci['skip_solrcloud_comp_execution']

# Solrcloud Monitoring attributes
node.set["enable_medusa_metrics"] = ci['enable_medusa_metrics']
node.set["medusa_log_file"] = "/opt/solr/log/medusa_stats.log"
node.set["enable_jmx_metrics"] = ci['enable_jmx_metrics']
node.set["jmx_medusa_log_file"] = "/opt/solr/log/jmx_medusa_stats.log"
node.set["jmx_metrics_level"] = ci['jmx_metrics_level']
node.set["jolokia_port"] = ci['jolokia_port']
node.set["graphite_servers"] = ci['graphite_servers']
node.set["graphite_prefix"] = ci['graphite_prefix']
node.set["graphite_logfiles_path"] = ci['graphite_logfiles_path']

node.set['solr_custom_component_version'] = ci['solr_custom_component_version']
node.set['solr_monitor_version'] = ci['solr_monitor_version']
node.set['solr_base_url'] = mirrors['solr_base_url'] #Example: http://apache.mirrors.hoobly.com/lucene/solr/6.6.0
# Environment should be picked up using the environment profile.
node.set['oo_environment'] = node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile].downcase
node.set['oo_cloud'] =node.workorder.cloud.ciName

setZkhostfqdn(node['zk_select'],ci)

node.set['solr_version'] = ci['solr_version']
node.set['solrmajorversion'] = "#{node['solr_version']}"[0,1]

node.set["default_config"] = "default_config"
node.set["default_data_driven_config"] = "default_data_driven_config"
node.set["forklift_default_config"] = "forklift_default_config"

node.set["port_no"] = "8080" if node['solr_version'].start_with? "4."
node.set["port_no"] = ci['port_no'] if (node['solr_version'].start_with? "6.") || (node['solr_version'].start_with? "5.") || (node['solr_version'].start_with? "7.")

if node['solr_version'].start_with? "5."
  node.set['config_url'] = node['solr_custom_params']['config_url_v5']
end

if node['solr_version'].start_with?("6.")
  node.set['config_url'] = node['solr_custom_params']['config_url_v6']
end

if node['solr_version'].start_with? "7."
  node.set['config_url'] = node['solr_custom_params']['config_url_v7']
end

node.set["installation_dir_path"] = ci['installation_dir_path']
node.set["data_dir_path"] = ci['data_dir_path']+"#{node['solrmajorversion']}"
node.set["enable_cinder"] = ci['enable_cinder']

# replace 'solrdata' substring with 'solrdata<major_version>' in heap dump path if provided
heap_dump_dir = ""
gc_tune_options = []
JSON.parse(ci['gc_tune_params']).each do |item|
     if item.start_with?("HeapDumpPath")
       item = item.gsub "solrdata/","solrdata#{node['solrmajorversion']}/"
       heap_dump_dir = item.split("=")[1]
     end
     gc_tune_options.push item
end
# Where heap dump will be created?
node.set["heap_dump_dir"] = heap_dump_dir
node.set["gc_tune_params"] = gc_tune_options
node.set["gc_log_params"] = ci['gc_log_params']
node.set["solr_opts_params"] = ci['solr_opts_params']
node.set["solr_mem_max"] = ci['solr_max_heap']
node.set["solr_mem_min"] = ci['solr_min_heap']

node.set['solr_collection_url'] = "http://#{node['ipaddress']}:#{node['port_no']}/solr/admin/collections"
node.set['solr_core_url'] = "http://#{node['ipaddress']}:#{node['port_no']}/solr/admin/cores"
node.set['clusterstatus']['uri'] = "http://#{node['ipaddress']}:#{node['port_no']}/solr/admin/collections?action=CLUSTERSTATUS&wt=json"
node.set['clusterstatus']['uri_v6'] = "http://#{node['ipaddress']}:#{node['port_no']}/solr/admin/zookeeper?detail=true&path=%2Fcollections"
node.set['aliases_uri_v6'] = "http://#{node['ipaddress']}:#{node['port_no']}/solr/admin/zookeeper?detail=true&path=%2Faliases.json"

node.set['solr_api_timeout_sec'] = (ci['solr_api_timeout_sec'] != nil && !ci['solr_api_timeout_sec'].empty?) ? ci['solr_api_timeout_sec'] : '300'

node_solr_portnum = node['port_no']
nodeip = "#{node['ipaddress']}"
node_solr_version = ci['solr_version']

cloud_provider_name = CloudProvider.get_cloud_provider_name(node)
Chef::Log.info("cloud_provider_name = #{cloud_provider_name}")
allow_ephemeral_on_azure = ci['allow_ephemeral_on_azure'] || "false"
node.set['azure_on_storage'] = 'false'
if cloud_provider_name == 'azure' && allow_ephemeral_on_azure == 'false'
  node.set['azure_on_storage'] = 'true'
  # As solr on azure always deployed with cinder/storage, do not additionally enable cinder otherwise data folder already on storage will also be link to some other mount point
  Chef::Log.info("cinder is enabled by default on azure. hence marking enable_cinder = false to prevent from creating additional link for data on storage or If you still want to use ephemeral, please select the flag 'Allow ephemeral on Azure' in solrcloud component")
  node.set["enable_cinder"] = "false"
  # Verify that blockstorage/cinder mount point is same as installation dir on solrcloud attr.
  CloudProvider.enforce_storage_use(node, node['cinder_volume_mountpoint'], volume_app_mount_point)
end

# To set the ip,port and version for each solrcloud component
Chef::Log.info(" Node IP = " + nodeip + ", Node solr Version = " + node_solr_version + ", solr port no = " + node['port_no'] )
puts "***RESULT:nodeip="+nodeip
puts "***RESULT:node_solr_version="+node_solr_version
puts "***RESULT:node_solr_portnum="+node['port_no']
  
# get the url_max_requests_per_sec_map where key is url pattern & value is maxRequestPerSec
# Append map index to value so that in case of multiple filters, each filter can have different name
# For ex. for each url patter the filter name will be as DoDFilter0, DoDFilter1..
# Also validate url_max_requests_per_sec_map for any empty key or/and value and non mueric value
solr_custom_params = node['solr_custom_params']
jetty_filter_url = (solr_custom_params.has_key?'jetty_filter_url')?solr_custom_params['jetty_filter_url']:""
jetty_filter_class = (solr_custom_params.has_key?'solr_dosfilter_class')?solr_custom_params['solr_dosfilter_class']:""
node.set['url_max_requests_per_sec_map'] = Hash.new() 
if ci.has_key?("url_max_requests_per_sec_map") 
  url_max_requests_per_sec_map = JSON.parse(ci['url_max_requests_per_sec_map'])
  url_max_requests_per_sec_map.each_with_index do |(key, value), index|
    if key == nil || key.strip.empty?
      puts "***FAULT:FATAL=Invalid url pattern for DoSFilter : #{key}"
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e  
    elsif value == nil || value.match(/\A[+-]?\d+?\Z/) == nil
      puts "***FAULT:FATAL=Invalid maxRequestsPerSec #{value} for DoSFilter url pattern #{key}"
      e = Exception.new("no backtrace")
      e.set_backtrace("")
      raise e  
    end
    url_max_requests_per_sec_map[key.strip] = "#{value.strip}:DoSFilter#{index}"
  end
  node.set['url_max_requests_per_sec_map'] = url_max_requests_per_sec_map
end

# if maxRequestsPerSec is provided, then DoS filter url must be provided
if !node['url_max_requests_per_sec_map'].empty?
  if jetty_filter_url.empty?
    error = "URL for Jetty-QoS/DoS-custom-filter must be provided if you are providing URL-patterns with maxRequestsPerSec attributes"
    puts "***FAULT:FATAL=#{error}"
    raise e
  elsif jetty_filter_class.empty?
    error = "DoS filter class for Jetty-QoS/DoS-custom-filter must be provided if you are providing URL-patterns with maxRequestsPerSec attributes"
    puts "***FAULT:FATAL=#{error}"
    raise e
  end
end

node.set['solr_user_name'] = ci['solr_user_name']
node.set['solr_user_password'] = ci['solr_user_password']
node.set['enable_authentication'] = ci['enable_authentication']
node.set['solr_admin_username'] = "solradmin"
node.set['solr_admin_password'] = "SOLR@cloud#ms"

compute_name = ""

node.set['skip_compute'] = 0

if oneops_action == false

  if !node.workorder.payLoad.ManagedVia[0][:ciName].nil?
    compute_name = node.workorder.payLoad.ManagedVia[0][:ciName]
  end

  computes = node.workorder.payLoad.has_key?("RequiresComputes") ? node.workorder.payLoad.RequiresComputes : node.workorder.payLoad.computes

  if !computes.nil? && computes.length > 0
    sorted_computes = computes.sort_by { |c| c.ciName}
    first_compute = sorted_computes[0]
    first_compute_ciname = first_compute[:ciName]

    if (compute_name == first_compute_ciname)
      Chef::Log.info("Solr-user component will run on compute: #{compute_name}")
    else
      node.set['skip_compute'] = 1
      Chef::Log.info("Solr-user component will not run on compute: #{compute_name}")
    end
  else
    Chef.log.info("****FATAL ERROR*******: The Solr cluster does not have any computes passed in the payload")
    return
  end
end

#wait for prior nodes in the deployment to completes (must be live after deployment)
if actionName == 'replace'
  verify_prior_nodes_live(node)

end
