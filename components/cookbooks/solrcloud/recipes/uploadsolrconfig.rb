#
# Cookbook Name :: solrcloud
# Recipe :: uploadsolrconfig.rb
#
# The recipe downloads the custom config from given url and uploads to Zookeeper.
#


include_recipe 'solrcloud::default'

extend SolrCloud::Util
# Wire SolrCloud util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)


args = ::JSON.parse(node.workorder.arglist)
custom_config_nexus_path = args["custom_config_nexus_path"]
config_name = args["config_name"]





if not node['solr_version'].start_with? "4."
  solr_config = node['user']['dir']+"/solr-config"+node['solr_version'][0,1];
end


if !custom_config_nexus_path.empty?
  if custom_config_nexus_path.include? "jar"
    config_dir = custom_config_nexus_path.split("/").last.split(".jar").first;
    if !config_dir.empty?
      config_jar = "#{config_dir}"+".jar";
    end
  else
    raise "Configuration jar file name is missing in the given path -- #{custom_config_nexus_path}."
  end
else
  raise "Required parameter (custom_config_nexus_path) is missing."
end

zkhost = node['zk_host_fqdns']
customdir = "custom-tmp-dir"
custom_dir_full_path = "#{solr_config}"+"/#{customdir}"
if (!"#{config_name}".empty?) && (!"#{config_jar}".empty?)
  remote_file "#{solr_config}/#{config_jar}" do
    source custom_config_nexus_path
    owner "app"
    group "app"
    mode '0777'
  end
  extractCustomConfig(solr_config, config_jar, custom_config_nexus_path, customdir)
  ruby_block 'validate_solr_config' do
    block do
      validate_and_upload_config_jar_contents(custom_dir_full_path, config_name)
    end
  end
else
  raise "Required parameter (config_name) is missing."
end

