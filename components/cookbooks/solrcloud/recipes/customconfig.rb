#
# Cookbook Name :: solrcloud
# Recipe :: customconfig.rb
#
# The recipe downloads the custom config from url and uploads to Zookeeper
#

include_recipe 'solrcloud::default'

extend SolrCloud::Util

# Wire SolrCloud util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)

config_dir = '';
config_jar = '';
solr_config = node['user']['dir']+"/solr-config";

customdir = "forklift-default-dir"
config_upload_or_download_path = "#{node['user']['dir']}/solr-config/"

if (node['solr_version'].start_with? "5.") || (node['solr_version'].start_with? "6.") || (node['solr_version'].start_with? "7.")
    solr_config = node['user']['dir']+"/solr-config"+node['solr_version'][0,1];
end

if node['config_url'] != nil && !node['config_url'].empty?
    if node['config_url'].include? "jar"
        # splitting on '/' and retrieve the jar name from the last split
        config_dir = node['config_url'].split("/").last.split(".jar").first;
        if !config_dir.empty?
            # append the .jar extension to the jar file name
            config_jar = "#{config_dir}"+".jar";
        end
        if (!node['forklift_default_config'].empty?) && (!config_jar.empty?)
            # Uploading the default forklift config to zookeeper
            remote_file "#{solr_config}/#{config_jar}" do
                source node['config_url']
                owner "app"
                group "app"
                mode '0777'
            end
            if (node['action_name'] != "update") && (node['action_name'] != "replace")
                computes = node.workorder.payLoad.has_key?("RequiresComputes") ? node.workorder.payLoad.RequiresComputes : node.workorder.payLoad.computes
                collections_exist = false
                computes.each do |compute|
                    unless compute[:ciName].nil?
                        if compute[:ciAttributes][:private_ip] != nil
                            collections_exist = collections_exists_on_cluster(compute[:ciAttributes][:private_ip], node['port_no'])
                            if collections_exist
                                break
                            end
                        end
                    end
                end
                if not collections_exist
                    extractCustomConfig(solr_config,config_jar,node['config_url'],customdir)
                    uploadCustomConfig(node['solr_version'],node['zk_host_fqdns'],node['forklift_default_config'],"#{solr_config}/#{customdir}")
                end
            end
        else
            raise "Required custom config name parameter is missing. Unable to upload the custom configuration to zookeeper."
        end
    else
        Chef::Log.error("Required to provide the location of custom config jar")
    end
else
    Chef::Log.info("Custom configuration url path is empty")
end


