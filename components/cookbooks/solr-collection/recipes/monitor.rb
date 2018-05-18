#
# Cookbook Name :: solr-collection
# Recipe :: monitor.rb
#
# The recipe copies the monitor scripts and its related libraries from inductor to all computes.
#


# Copy the check_shardstatus.rb.erb monitor to /opt/nagios/libexec/check_shardstatus.rb location
template "/opt/nagios/libexec/check_shardstatus.rb" do
  source "check_shardstatus.rb.erb"
  owner "app"
  group "app"
  mode "0755"
  variables({
    :port_no => node['port_num']
  })
  action :create
end

cloud_provider = CloudProvider.new(node)
# get map of key=>cloud_name or fault_domain_update_domain and value => list of compute ips
cloud_to_compute_ips_map = cloud_provider.get_zone_to_compute_ip_map()
Chef::Log.info("cloud_to_compute_ips_map = #{cloud_to_compute_ips_map.to_json}")

# Copy the replica_distribution_validation.rb.erb monitor to /opt/nagios/libexec/replica_distribution_validation.rb location
template "/opt/nagios/libexec/replica_distribution_validation.rb" do
  source "replica_distribution_validation.rb.erb"
  owner "app"
  group "app"
  mode "0755"
  variables({
    :cloud_to_compute_ips_map => cloud_to_compute_ips_map.to_json
  })
  action :create
end