#
# Cookbook Name :: solrcloud
# Recipe :: monitors.rb
#
# The recipe copies the monitor scripts from the inductor to computes in the cluster.
#


# Copying /opt/nagios/libexec/check_solrprocess.sh script
template "/opt/nagios/libexec/check_solrprocess.sh" do
  source "check_solrprocess.sh.erb"
  owner node['solr']['user']
  group node['solr']['user']
  mode "0755"
  action :create
end

# create "check_solr_zk_conn.sh" script for nagios
template "/opt/nagios/libexec/check_solr_zk_conn.sh" do
  source "check_solr_zk_conn.sh.erb"
  owner node['solr']['user']
  group node['solr']['user']
  mode  '0755'
  action :create
end

# create "check_solr_metrics_monitor.sh" script for nagios
template "/opt/nagios/libexec/check_solr_metrics_monitor.sh" do
  source "check_solr_metrics_monitor.sh.erb"
  owner node['solr']['user']
  group node['solr']['user']
  mode  '0755'
  action :create
end

# Copying /opt/nagios/libexec/solr_util.rb script
template "/opt/nagios/libexec/solr_util.rb" do
  source "solr_util.rb.erb"
  owner node['solr']['user']
  group node['solr']['user']
  mode "0755"
  action :create
end

# Copying /opt/nagios/libexec/check_solr_mbeanstat.rb script
template "/opt/nagios/libexec/check_solr_mbeanstat.rb" do
  source "check_solr_mbeanstat.rb.erb"
  owner node['solr']['user']
  group node['solr']['user']
  mode "0755"
  action :create
  variables({
    :solr_jmx_port => node['jmx_port']
  })
end

# Copying /opt/nagios/libexec/check_solr_process.rb script
template "/opt/nagios/libexec/check_solr_process.rb" do
  source "check_solr_process.rb.erb"
  owner node['solr']['user']
  group node['solr']['user']
  mode "0755"
  action :create
end



