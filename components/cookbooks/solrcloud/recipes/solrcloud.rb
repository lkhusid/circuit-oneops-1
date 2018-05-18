#
# Cookbook Name :: solrcloud
# Recipe :: solrcloud.rb
#
# The recipe extracts the solr distribution, copies the WEB-INF/lib/ jars to solr-war-lib folder and sets up the solrcloud
#
#


extend SolrCloud::Util

# Wire solrcloud util to chef resources.
Chef::Resource::RubyBlock.send(:include, SolrCloud::Util)


begin
  if node.workorder.ci != nil
    ci = node.workorder.ci.ciAttributes;
  end
rescue
ensure
end

begin
  if node.workorder.rfcCi != nil
    ci = node.workorder.rfcCi.ciAttributes;
  end
rescue
ensure
end

solr_package_type = "solr"
solr_format = "tgz"

solr_download_path = "/tmp";
solr_file_name = "#{solr_package_type}-"+node['solr_version']+".#{solr_format}"
solr_file_woext = "#{solr_package_type}-"+node['solr_version']
solr_url = "#{node['solr_base_url']}/#{solr_package_type}/"+node['solr_version']+"/#{solr_file_name}"
solr_filepath = "#{solr_download_path}/#{solr_file_name}"

ns_path = node.workorder.rfcCi.nsPath.split(/\//)
oo_org = ns_path[1]
oo_assembly = ns_path[2]
oo_environment_name = ns_path[3]
oo_platform = ns_path[5]

# Download solr package from path #{solr_url}
remote_file solr_filepath do
  source "#{solr_url}"
  owner "#{node['solr']['user']}"
  group "#{node['solr']['user']}"
  mode '0644'
  action :create_if_missing
end

if node['solr_version'].start_with? "4."

  solr_extract_path = "#{node['solr_download_path']}/extract"
  solr_extract_war_path = "#{solr_extract_path}/extract-war"
  solr_war_lib = "#{node['user']['dir']}/solr-war-lib"
  solr_config = "#{node['user']['dir']}/solr-config"
  solr_cores = "#{node['user']['dir']}/solr-cores"
  solr_default_dir = "#{solr_config}/default"


  ["#{solr_war_lib}" ,"#{solr_config}","#{solr_default_dir}","#{solr_cores}","#{solr_extract_path}" ].each { |dir|
    Chef::Log.info("creating #{dir} for users")
    directory dir do
      not_if { ::File.directory?(dir) }
      owner node['solr']['user']
      group node['solr']['user']
      mode "0755"
      recursive true
      action :create
    end
  }

  # Unpacks solr tgz package and extracts solr.war
  # Copies the WEB-INF/lib jars to /app/solr-war-lib directory
  # Copies the default configuration files to /app/solr-config/default directory
  # Copies the ext/libs to tomcat/WEB-INF/lib and /app/solr-war-lib directory
  bash 'unpack_solr_war' do
    code <<-EOH
      cd #{node['user']['dir']}
      rm -rf solr-*.txt
      echo #{node['solr_version']} > solr-#{node['solr_version']}.txt
      mkdir #{solr_extract_path}
      mv /tmp/#{solr_file_name} #{solr_extract_path}
      cd #{solr_extract_path}
      mkdir extract-war
      tar -xf #{solr_file_name}
      cp #{solr_file_woext}/dist/#{solr_file_woext}.war ./extract-war
      cd ./extract-war
      jar xvf #{solr_file_woext}.war
      rm -rf #{node['user']['dir']}/solr-war-lib/*
      rm -rf #{node['user']['dir']}/solr.war
      cp #{solr_extract_war_path}/WEB-INF/lib/* #{solr_war_lib}
      cp #{solr_file_woext}.war solr.war
      cp solr.war #{node['user']['dir']}
      rm -rf #{node['user']['dir']}/solr-config/default/*
      cp -irf #{solr_extract_path}/#{solr_file_woext}/example/solr/collection1/conf/* #{node['user']['dir']}/solr-config/default/
      cp #{solr_extract_path}/#{solr_file_woext}/example/lib/ext/*.jar #{solr_war_lib}
      cp #{solr_extract_path}/#{solr_file_woext}/example/lib/ext/*.jar #{node['tomcat']['dir']}/lib
    EOH
    not_if { ::File.exists?("#{node['user']['dir']}/solr-#{node['solr_version']}.txt") }
  end

  # Inserts zookeeper fqdn connection string to the setenv.sh file
  bash "insert_zookeeper_config" do
    code <<-EOH
      grep -q -F 'zkHost' #{node['tomcat']['dir']}/bin/setenv.sh || echo 'export CATALINA_OPTS=\"\$CATALINA_OPTS -DzkHost=#{node['zk_host_fqdns']}\"' >> #{node['tomcat']['dir']}/bin/setenv.sh
    EOH
  end

  # Inserts jmx config properties to the setenv.sh file
  bash "insert_jmx_config" do
    code <<-EOH
      grep -q -F 'jmxremote' #{node['tomcat']['dir']}/bin/setenv.sh || echo 'export CATALINA_OPTS=\"\$CATALINA_OPTS -Djava.awt.headless=true -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=#{node['jmx_port']} -Dcom.sun.management.jmxremote.rmi.port=#{node['jmx_port']}\"' >> #{node['tomcat']['dir']}/bin/setenv.sh
    EOH
    not_if { "#{node['jmx_port']}".empty? }
  end

  # Create or Update the #{node['user']['dir']}/solr-cores/solr.xml in /app/solr-cores directory
  cookbook_file "#{node['user']['dir']}/solr-cores/solr.xml" do
    source "solr.xml"
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
    action :create_if_missing
  end

  execute 'notify-tomcat-restart' do
    command "service tomcat#{node['tomcatversion']} restart"
    user "root"
    action :run
    only_if { ::File.exists?("/etc/init.d/tomcat#{node['tomcatversion']}") }
  end

  # Uploading the default config to zookeeper.
  # default config is not recommended for production use as it does not have IgnoreCommitUpdateProcessor, hence its commented out here
  # If really required, it should be uploaded to zookeeper from the command line
  # uploadDefaultConfig(node['solr_version'],node['zk_host_fqdns'],node['default_config'])

end

if (node['solr_version'].start_with? "6.") || (node['solr_version'].start_with? "5.") || (node['solr_version'].start_with? "7.")

  solr_war_lib_dir = node['user']['dir']+"/solr-war-lib"+node['solrmajorversion']
  solr_config_dir = node['user']['dir']+"/solr-config"+node['solrmajorversion']

  ["#{solr_war_lib_dir}", "#{solr_config_dir}", "#{node['data_dir_path']}" ].each { |dir|
    Chef::Log.info("creating #{dir} for users")
    directory dir do
      owner node['solr']['user']
      group node['solr']['user']
      mode "0755"
      recursive true
      action :create
    end
  }

  # create heap_dump_dir if provided
  if node["heap_dump_dir"] != nil && !node["heap_dump_dir"].empty?
  	directory node["heap_dump_dir"] do
      owner node['solr']['user']
      group node['solr']['user']
      mode "0755"
      recursive true
      action :create
    end
  end
  # Creates the data symlink to /blockstorage when the volume added is Cinder
  Chef::Log.info("Will create a symlink between data directory and blockstorage if Cinder is enabled.")
  # Create the symlink for the data directory in /app/solrdata+#{majorversion} to the mountpoint on the cinder storage
  if node['enable_cinder'] == "true"
    Chef::Log.info("Creating a symlink between data directory and blockstorage, since Cinder is enabled.")
    create_symlink_from_data_to_cinder_mountpoint()
  else
    Chef::Log.warn("Will not create a symlink between data directory and blockstorage, since Cinder is disabled.")
    Chef::Log.info("If data is a symlink, then we will copy the data from Cinder/ symlink to the data directory which is hosted on Ephemeral volume.")
    include_recipe 'solrcloud::disable_storage'
  end

  #install_solr_service using -n option to install without starting service
  install_command = "sudo #{solr_download_path}/#{solr_file_woext}/bin/install_solr_service.sh #{solr_download_path}/#{solr_file_name} -i #{node['installation_dir_path']} -d #{node['data_dir_path']} -u #{node['solr']['user']} -p #{node['port_no']} -s solr#{node['solrmajorversion']} -n"
  Chef::Log.info("install_command = #{install_command}")

  # Install solr only if-
  # Add compute
  # Replace compute in openstack
  # Replace compute in azure if no storage. (In case of storage, binaries are already installed on disk)
  if node['action_name'] == "add" || (node['action_name'] == "replace" && node['azure_on_storage'] == 'false')

    # Extracts solr package.
    # solr_download_path = /tmp
    # solr_file_name = solr-7.x.x.tgz or solr-6.x.x.tgz
    execute "extract_solr_package" do
      Chef::Log.info(solr_download_path)
      Chef::Log.info(solr_file_name)
      cmd =  "#{solr_download_path}/#{solr_file_name}"
      Chef::Log.info("Extracting Solr archive with command: #{cmd}")
      command "tar -xf #{solr_download_path}/#{solr_file_name} -C #{solr_download_path}"
    end

    # Modify the permissions to the installation script(install_solr_service.sh).
    # solr_file_woext = solr-6.x.x or solr-7.x.x
    execute "modify_perm_install_script" do
      Chef::Log.info(solr_file_woext)
      command "sudo chmod 777 #{solr_download_path}/#{solr_file_woext}/bin/install_solr_service.sh"
    end

    # Remove solr service file from /etc/init.d directory if exists
    # Execute installation script (install_solr_service.sh) and install solr
    bash "install_solr" do
      code <<-EOH
        unlink #{node['installation_dir_path']}/solr#{node['solrmajorversion']}
        [ -e /etc/init.d/solr#{node['solrmajorversion']} ] && rm -- /etc/init.d/solr#{node['solrmajorversion']}
        #{install_command}
      EOH
    end

    # Copy jars from lib/ext and WEB-INF/lib directories to /app/solr-war-lib6 or /app/solr-war-lib7 directory.
    bash "copy_jars" do
      code <<-EOH
        sudo cp #{node['installation_dir_path']}/solr#{node['solrmajorversion']}/server/lib/ext/* #{node['user']['dir']}/solr-war-lib#{node['solrmajorversion']}
        sudo cp #{node['installation_dir_path']}/solr#{node['solrmajorversion']}/server/solr-webapp/webapp/WEB-INF/lib/* #{node['user']['dir']}/solr-war-lib#{node['solrmajorversion']}
      EOH
    end

  end

  # maxRequestsPerSec is provided then download and copy the custom filter to server/lib
  jetty_filter_url = node['solr_custom_params']['jetty_filter_url']
  if !node['url_max_requests_per_sec_map'].empty?
    dest_path = "/app/solr-jetty-servlets.jar"
    jetty_lib_path = "/app/solr#{node['solrmajorversion']}/server/lib"
    if !File.exists?(dest_path)
      shared_download_http jetty_filter_url do
        path dest_path
        mode "0644"
        action :create
      end
    end
    execute "move file to jetty lib" do
      command "cp #{dest_path} #{jetty_lib_path}"
    end
  else
    Chef::Log.info("Ignoring filter-jar #{jetty_filter_url} because there are no URL-patterns with maxRequestsPerSec attributes")
  end
  
  # Override the web.xml file to include user input. for ex. Url pattern & maxRequestsPerSec for limiting the requests
  template "/app/solr#{node['solrmajorversion']}/server/solr-webapp/webapp/WEB-INF/web.xml" do
    owner "root"
    group "root"
    mode '0644'
    source 'web.xml.erb'
    notifies :run, "ruby_block[solr_restart_warning]", :delayed
  end
  
  # Create or Update #{node['data_dir_path']}/log4j.properties file
  template "#{node['data_dir_path']}/log4j.properties" do
    source 'log4j.properties.solr.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
  end

  if (node['enable_authentication'] != nil && node['enable_authentication'] == "true")
    template "#{node['data_dir_path']}/http_client.properties" do
      source 'http_client.properties.erb'
      owner node['solr']['user']
      group node['solr']['user']
      mode '0755'
      notifies :run, "ruby_block[solr_restart_warning]", :delayed
    end
  end

  # Create or Update #{node['data_dir_path']}/solr.in.sh file
  template "#{node['data_dir_path']}/solr.in.sh" do
    source 'solr.in.sh.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
    notifies :run, "ruby_block[solr_restart_warning]", :delayed
  end

  # Create or Update zkcli.sh file under the below path
  template "#{node['installation_dir_path']}/solr#{node['solrmajorversion']}/server/scripts/cloud-scripts/zkcli.sh" do
    source 'zkcli.sh.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
  end



  # Create or Update /etc/init.d/solr#{node['solrmajorversion']} service
  template "/etc/init.d/solr#{node['solrmajorversion']}" do
    source 'solr.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
    notifies :run, "ruby_block[solr_restart_warning]", :delayed
  end

  # Create or Update /app/solrdata#{node['solrmajorversion']}/solr.xml
  template "#{node['data_dir_path']}/data/solr.xml" do
    source 'solr5.xml.erb'
    owner node['solr']['user']
    group node['solr']['user']
    mode '0755'
    notifies :run, "ruby_block[solr_restart_warning]", :delayed
  end

  # Uploading the default data driven config to zookeeper.
  # data-driven-config is not recommended for production use, hence its commented out here
  # If really required, it should be uploaded to zookeeper from the command line
  # uploadDefaultConfig(node['solr_version'],node['zk_host_fqdns'],node['default_data_driven_config'])

  # Copy the solrmonitor script from the jar to the location /opt/solr

  solr_monitor_version = node['solr_monitor_version']

  artifact_descriptor = "#{node['solr_custom_params']['solr_monitor_artifact']}:#{solr_monitor_version}:jar"

  if (solr_monitor_version =~ /SNAPSHOT/)
    artifact_urlbase = node['solr_custom_params']['snapshot_urlbase']
  else
    artifact_urlbase = node['solr_custom_params']['release_urlbase']
  end

  solr_monitor_url, solr_monitor_version = SolrCustomComponentArtifact::get_artifact_url(artifact_descriptor, artifact_urlbase)

  Chef::Log.info( "solr_monitor_url - #{solr_monitor_url} and solr_monitor_version -  #{solr_monitor_version}")

  # Getting rid of SNAPSHOT string from the version name as we will need to manage release and snapshot releases in the same way
  # if (solr_monitor_version.to_s =~ /SNAPSHOT/)
  #   solr_monitor_version = solr_monitor_version.gsub('-SNAPSHOT', '')
  # end

  solr_monitor_jar = "solr-monitor-#{solr_monitor_version}.jar"
  solr_monitor_dir = "/opt"
  solr_monitor_custom_dir = "solr"

  # Fetch the solr monitor artifact and copy it to /opt
  remote_file "#{solr_monitor_dir}/#{solr_monitor_jar}" do
    user 'app'
    group 'app'
    source solr_monitor_url
    not_if { ::File.exists?("#{solr_monitor_dir}/#{solr_monitor_jar}") }
  end


  # Extract the jar contents and put it in /opt/solr.
  # The extracted contents will have solrmonitor directory under which we have the scripts and the metrics directory. Metrics directory has the metrics list in yaml file
  extractCustomConfig(solr_monitor_dir, solr_monitor_jar, solr_monitor_url, solr_monitor_custom_dir)

  directory '/opt/solr/solrmonitor/spiked-metrics' do
    owner 'app'
    group 'app'
    mode '0755'
    action :create
  end

  # Make sure the solr /opt directories exist and have the right permissions
  %w[ /opt/solr /opt/solr/log /opt/solr/solrmonitor ].each do |app_dir|
    directory app_dir do
      owner 'app'
      group 'app'
      mode '0777'
    end
  end

  execute "fix /opt/solr/solrmonitor owner and group" do
    command "sudo chown app /opt/solr/solrmonitor/*; sudo chgrp app /opt/solr/solrmonitor/*; sudo chmod 0777 /opt/solr/solrmonitor/*"
  end

  template "/opt/solr/solrmonitor/metrics-tool.rb" do
    source "metrics-tool.erb"
    owner 'app'
    group 'app'
    mode "0755"
    variables({
                  :port_no => node['port_no'],
                  :enable_medusa_metrics => node['enable_medusa_metrics'],
                  :medusa_log_file => node['medusa_log_file'],
                  :solr_version => node['solr_version'],
                  :metric_level => node['jmx_metrics_level'],
                  :jolokia_port => node['jolokia_port'],
                  :solr_jmx_port => node['jmx_port'],
                  :enable_jmx_metrics => node['enable_jmx_metrics'],
                  :jmx_medusa_log_file => node['jmx_medusa_log_file'],
                  :admin_user => user,
                  :admin_password => '',
                  :graphite_servers => node['graphite_servers'],
                  :graphite_prefix => node['graphite_prefix'],
                  :graphite_logfiles_path => node['graphite_logfiles_path'],
                  :oo_org => oo_org,
                  :oo_assembly => oo_assembly,
                  :oo_env => node['oo_environment'],
                  :oo_platform => oo_platform,
                  :oo_cloud => node['oo_cloud'],
                  :node_ip => node['ipaddress'],
                  :oo_environment_name => oo_environment_name
              })
  end

  file "#{node['medusa_log_file']}" do
    mode '0644'
    owner 'root'
    group 'root'
    action :create_if_missing
  end

  file "#{node['jmx_medusa_log_file']}" do
    mode '0644'
    owner 'root'
    group 'root'
    action :create_if_missing
  end

  # Check if the enable_medusa_metrics is enabled. If it is true, then push to medusa
  if (node['enable_medusa_metrics'] == "true" || node['enable_jmx_metrics'] == "true")
    Chef::Log.info("Enabling the Medusa Metrics, since the flag is true.")
    cron "metrics-tool" do
      user 'root'
      minute "*/1"
      command "cd /opt/solr/solrmonitor/; ruby metrics-tool.rb; ruby metrics-spike-detector.rb"
      only_if { ::File.exists?("/opt/solr/solrmonitor/metrics-tool.rb") }
    end
  else
    Chef::Log.info("Disabling the Medusa Metrics, since the flag is - #{node['enable_medusa_metrics']}")
    cron "metrics-tool" do
      user 'root'
      action :delete
    end
  end

  # Adding solr custom component

  solr_custom_comp_version = node['solr_custom_component_version']

  artifact_descriptor = "#{node['solr_custom_params']['solr_custom_comp_artifact']}:#{solr_custom_comp_version}:jar"
  
  if (solr_custom_comp_version =~ /SNAPSHOT/)
    artifact_urlbase = node['solr_custom_params']['snapshot_urlbase']
  else
    artifact_urlbase = node['solr_custom_params']['release_urlbase']
  end

  solr_custom_comp_url, solr_custom_comp_version = SolrCustomComponentArtifact::get_artifact_url(artifact_descriptor, artifact_urlbase)

  Chef::Log.info( "solr_custom_comp_url - #{solr_custom_comp_url} and solr_custom_comp_version -  #{solr_custom_comp_version}")

  if (solr_custom_comp_version.to_s =~ /SNAPSHOT/)
    solr_custom_comp_version = solr_custom_comp_version.gsub('-SNAPSHOT', '')
  end

  solr_custom_comp_jar = "solr-custom-components-#{solr_custom_comp_version}.jar"
  solr_plugins_dir = "/app/solr#{node['solrmajorversion']}/plugins"

  ["#{solr_plugins_dir}"].each { |dir|
    Chef::Log.info("creating #{dir}")
    directory dir do
      owner node['solr']['user']
      group node['solr']['user']
      mode "0755"
      recursive true
      action :create
    end
  }

  # Fetch the custom solr component artifact
  remote_file "#{solr_plugins_dir}/#{solr_custom_comp_jar}" do
    user 'app'
    group 'app'
    source solr_custom_comp_url
    only_if { ::File.directory?("#{solr_plugins_dir}") }
  end

  solr_restart_warning = ruby_block 'solr_restart_warning' do
    block do
      Chef::Log.warn("Some Solr-files have changed and they will take effect on Solr restart. You can do so from the restart action for solrcloud component in Operations phase.")
    end
    action :nothing
  end
  # Note: No restart on update. User should manually restart (rolling restart) from action on update
  if node['action_name'] =~ /add|replace/

    #stop solr if already running. for ex. during add/replace, node started but failed after and retry
    #will fail on start as the node is already running, hence we must stop the node before start again
    execute "stop_solr" do
      command "service solr#{node['solrmajorversion']} stop"
      returns [0,1]
    end

    service "solr#{node['solrmajorversion']}" do
      provider Chef::Provider::Service::Init # for centos 7, provider should use system.d if required
      supports  :restart => true, :status => true, :stop => true, :start => true
      action :start
    end
  elsif node['action_name'] == "update" && update_found(node)
    solr_restart_warning.action(:run)
  end
  
end
