#
# Cookbook Name :: solrcloud
# Recipe :: add.rb
#
# The recipe stops the solrcloud on the node.
#

extend SolrAuth::AuthUtils


ruby_block "configure_authentication" do

  block do
    zk_classpath=".:#{node['user']['dir']}/solr-war-lib#{node['solr_version'][0,1]}/*"
    zk_host = node['zk_host_fqdns']
    solr_admin_user = node['solr_admin_username']
    solr_admin_password = node['solr_admin_password']
    solr_majorversion = "#{node['solr_version']}"[0,1]
    solr_install_dir = "#{node['installation_dir_path']}/solr#{solr_majorversion}"

    auth_configurer = AuthConfigurer.new(node['ipaddress'], node['port_no'], solr_admin_user, solr_admin_password,
                                 node['solr_user_name'], node['solr_user_password'], zk_classpath, zk_host, solr_install_dir)

    if (node['action_name'] == 'update')
      if (node['enable_authentication'] == "true")
        Chef::Log.info("Creating the Solr secrete file")
        auth_configurer.create_secrete_file()
      else
        Chef::Log.info("Deleting the Solr secrete file")
        auth_configurer.delete_secret_file()
      end

    elsif (node['enable_authentication'] == "true")
      Chef::Log.info("Creating the Solr secrete file")
      auth_configurer.create_secrete_file()
    end


    skip_compute = node['skip_compute']

    if skip_compute > 0
      # The regular return statement here throws a LocalJumpError
      # You have to either call next or break. The next statement returns the value to the caller of the block
      #
      next
    end

    Chef::Log.info("Running solr-authentication component on this compute")

    if (node['enable_authentication'] == "true")
      auth_configurer.enable_authentication()
    else
      auth_configurer.disable_authentication()
    end

  end

end









  
