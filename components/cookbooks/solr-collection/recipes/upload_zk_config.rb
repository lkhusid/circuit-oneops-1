#
# Cookbook Name :: solrcloud
# Recipe :: upload_zk_config.rb
#
# The recipe downloads the custom config from given url and uploads to Zookeeper.
#
require 'date'

include_recipe 'solr-collection::default'

extend SolrCloud::Util
extend SolrCollection::Util

# Wire SolrCloud Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)
# Wire SolrCollection Util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCollection::Util)


config_name = node['config_name']
user_dir = "/app"

if ("#{config_name}".empty?)
  raise "Required parameter (config_name) is missing."
end

solr_config = user_dir+"/solr-config"
if not node['solr_version'].start_with? "4."
  solr_config = user_dir+"/solr-config"+node['solr_version'][0,1];
end

solrcloud_ci = node.workorder.payLoad.SolrCloudPayload[0].ciAttributes
setZkhostfqdn(solrcloud_ci['zk_select'], solrcloud_ci)

custom_config_dir = "custom-tmp-dir"
custom_dir_full_path = "#{solr_config}"+"/#{custom_config_dir}"


# Check if url for the zk config is provided, then use the nexus path to upload the zk config,
# otherwise try to use the config which is provided by the user in the config_name field
if node.has_key?("zk_config_urlbase") && !node["zk_config_urlbase"].empty?

  custom_config_nexus_path = node['zk_config_urlbase']

  date_to_be_checked_string = node['date_safety_check_for_config_update']
  date_to_be_checked = Date.strptime(date_to_be_checked_string, "%Y-%m-%d")

  today_date_string = Time.now.strftime("%Y-%m-%d")
  today_date = Date.strptime(today_date_string, "%Y-%m-%d")
  Chef::Log.info("Today's date - #{today_date}")
  Chef::Log.info("Date to be checked - #{date_to_be_checked}")

  date_difference_in_days = (date_to_be_checked - today_date).to_i.abs
  Chef::Log.info("Difference in days - #{date_difference_in_days}")

  # Download the config with the config name to check if the config already exists in the zk
  downloadDefaultConfig(node['solr_version'], node['zk_host_fqdns'], config_name, "#{solr_config}/#{config_name}")


  if !custom_config_nexus_path.include? "jar"
    raise "Configuration jar file name is missing in the given path -- #{custom_config_nexus_path}."
  end

  config_dir = custom_config_nexus_path.split("/").last.split(".jar").first;
  if !config_dir.empty?
    config_jar = "#{config_dir}"+".jar";
  end

  if ("#{config_jar}".empty?)
    raise "Required parameter (config_name) is missing."
  end

  remote_file "#{solr_config}/#{config_jar}" do
    source custom_config_nexus_path
    owner "app"
    group "app"
    mode '0777'
  end

  # Check if config is already uploaded to ZK. If the config exists in the config_name directory, then check the date provided by user.
  if File.directory?("#{solr_config}/#{config_name}")

    Chef::Log.info("Given config is located in ZK.")
    extracted_config_dir = "extracted_config_dir_for_diff"

    # If the date provided by user is today, then upload the new configuration. Otherwise, compare if there is any change in the config user provided with the already uploaded one and upload if there is any
    if date_difference_in_days <= 1
      Chef::Log.info("Given config is located in ZK and the user has provided today\'s date. Uploading the new config to ZK.")
      is_valid_date_check = true

      # Compare the directories and if they match then ignore upload to ZK. Otherwise upload the new config to ZK
      extract_compare_directories_and_perform_action(solr_config, config_name, extracted_config_dir, config_jar, custom_config_nexus_path, custom_dir_full_path, custom_config_dir, is_valid_date_check)
    else
      Chef::Log.info("User didn't provide today\'s date. So extracting the contents from the given Config URL and comparing with the uploaded ZK config.")
      is_valid_date_check = false

      # Compare the directories and if they match then ignore upload to ZK. Otherwise raise an exception regarding the date mismatch
      extract_compare_directories_and_perform_action(solr_config, config_name, extracted_config_dir, config_jar, custom_config_nexus_path, custom_dir_full_path, custom_config_dir, is_valid_date_check)
    end

  else
    Chef::Log.info("Uploading a new configuration to ZK.")

    extractCustomConfig(solr_config, config_jar, custom_config_nexus_path, custom_config_dir)

    props_map = get_prop_metadata_for_solrconfig_update()

    ruby_block 'update_solrconfig' do
      block do
        update_solrconfig_and_override_properties("#{solr_config}/#{custom_config_dir}/solrconfig.xml", props_map, true)
      end
    end

    ruby_block 'validate_and_upload_solr_config' do
      block do
        validate_and_upload_config_jar_contents(custom_dir_full_path, config_name)
        run_reload_collection(node['collection_name'], node['port_num'])

      end

    end

  end

else
  solrconfig_contains_update_processor_chain = true
  downloadDefaultConfig(node['solr_version'], node['zk_host_fqdns'], config_name, custom_dir_full_path)
  if File.directory?("#{custom_dir_full_path}")
    ruby_block 'update_solrconfig' do
      block do
        FileUtils.cp("#{custom_dir_full_path}/solrconfig.xml", "#{custom_dir_full_path}/solrconfig.xml.tmp")
        props_map = get_prop_metadata_for_solrconfig_update()
        solrconfig_contains_update_processor_chain = update_solrconfig_and_override_properties("#{custom_dir_full_path}/solrconfig.xml.tmp", props_map, solrconfig_contains_update_processor_chain)
      end
    end

    bash 'diff_solrconfig_xml' do
      code <<-EOH
        /tmp/xmldiffs.py  #{custom_dir_full_path}/solrconfig.xml #{custom_dir_full_path}/solrconfig.xml.tmp | sudo tee /tmp/diff_solrconfig.xml.txt
      EOH
    end

    ruby_block 'upload_solrconfig_if_changes_found' do
      block do
        if not File.zero? "/tmp/diff_solrconfig.xml.txt"
          Chef::Log.info("After applying the configuration from the solr-collection component, we found some changes in the configuration. So uploading the updated configuration to ZK.")
          FileUtils.mv("#{custom_dir_full_path}/solrconfig.xml.tmp", "#{custom_dir_full_path}/solrconfig.xml")
          validate_and_upload_config_jar_contents("#{custom_dir_full_path}", "#{config_name}")
          run_reload_collection(node['collection_name'], node['port_num'])

        else
          Chef::Log.warn("URL for the ZK config is not provided, also there were no changes found in the config to upload to Zookeeper")
          FileUtils.rm "#{custom_dir_full_path}/solrconfig.xml.tmp"
        end

        FileUtils.rm "/tmp/xmldiffs.py"
      end
    end

    # check if initParams has a default processor from defined updateRequestProcessorChains defined in the solrconfig
    # if solrconfig_contains_update_processor_chain
    #   check_default_chain_is_set()
    # end
    
  end

  bash 'remove_config_dir' do
    code <<-EOH
      rm -rf #{custom_dir_full_path}
    EOH
  end

end
