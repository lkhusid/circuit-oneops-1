# Reading for type of action.
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
  actionName = node.workorder.rfcCi.rfcAction
else
  ci = node.workorder.ci
  actionName = node.workorder.actionName
end

# Reading/Setting Configuration parameters.
node.default[:incremental_backups] = ci[:ciAttributes][:incremental_backups] || "false"
node.default[:max_heap_size] = ci[:ciAttributes][:max_heap_size]
node.default[:heap_newsize] = ci[:ciAttributes][:heap_newsize]

if ci.ciAttributes.has_key?("jvm_opts")
  node.default[:jvm_opts] = ci.ciAttributes.jvm_opts
end

node.default[:version] = ci.ciAttributes.version

localIp = node[:ipaddress]
if actionName == 'replace'
  node.default[:initial_seeds] = Cassandra::Util.find_seeds(node, localIp)
  # While replacing, take node_version as the default.
  if ci.ciAttributes.has_key?("node_version") && ci.ciAttributes.node_version != nil
    node.default[:version] = ci.ciAttributes.node_version
  end
else
  node.default[:initial_seeds] = Cassandra::Util.find_seeds(node, nil)
end

cassandra_home = node.default[:cassandra_home]
cassandra_current = "#{cassandra_home}/current"

node.default[:data_file_directories] = "#{cassandra_home}/data"
node.default[:commitlog_directory] = "#{cassandra_home}/commitlog"
node.default[:saved_caches_directory] = "#{cassandra_home}/data/saved_caches"
node.default[:cluster_name] = ci.ciAttributes.cluster
sub_dir = "apache-cassandra/#{node[:version]}"
tgz_file = "apache-cassandra-#{node[:version]}-bin.tar.gz"
untar_dir = "#{cassandra_home}/apache-cassandra-#{node[:version]}"

tmp = Chef::Config[:file_cache_path]
services = node[:workorder][:services]
if services.nil? || !services.has_key?(:maven)
  Chef::Log.error('Please make sure your cloud has Service nexus added.')
  exit 1
end

# Downloading and extracting Cassandra binaries.
cloud_name = node[:workorder][:cloud][:ciName]
node.default[:cloud_name] = cloud_name
Chef::Log.info("Using cloud: #{cloud_name}")
cloud_services = services[:maven][cloud_name]
cassandra_download_url = cloud_services[:ciAttributes][:url] + "content/repositories/central/org/apache/cassandra/#{sub_dir}/#{tgz_file}"
dest_file = "#{tmp}/#{tgz_file}"

if actionName == 'upgrade'
  `curl -o #{dest_file} #{cassandra_download_url}`
else
  unless File.exists?(dest_file)
    shared_download_http cassandra_download_url do
      path dest_file
      action :create
      if node[:apache_cassandra][:checksum] && !node[:apache_cassandra][:checksum].empty?
        checksum node[:apache_cassandra][:checksum]
      end
    end
  end
end

execute "untar_cassandra" do
  command "tar -zxf #{dest_file}; rm -fr #{cassandra_current} ; ln -sf #{untar_dir} #{cassandra_current}"
  cwd "#{cassandra_home}"
end

execute "Set CASSANDRA_HOME Ownership to Cassandra User" do
  command "chown -R cassandra:cassandra #{cassandra_home}"
end


execute "link_cassandra" do
  command "rm -fr /opt/cassandra ; ln -sf #{cassandra_current} /opt/cassandra"
  cwd "/opt"
end

include_recipe "apache_cassandra::add_user_dirs"

template "#{cassandra_current}/conf/cassandra-env.sh" do
  source "cassandra-env.sh.erb"
  owner "cassandra"
  group "cassandra"
  mode 0644
end

template "#{cassandra_current}/conf/jvm.options" do
  source "jvm.options.erb"
  owner "cassandra"
  group "cassandra"
  mode 0644
end

template "/tmp/replace_seed_info.sh" do
  source "replace_seed_info.erb"
  owner "cassandra"
  group "cassandra"
  mode 0644
end

template "/etc/init.d/cassandra" do
  source "initd.erb"
  owner "cassandra"
  group "cassandra"
  mode 0700
end

template "#{cassandra_home}/service_status.sh" do
  source 'service_status.sh.erb'
end
