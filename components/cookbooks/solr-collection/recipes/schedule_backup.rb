
extend SolrCloud::Util

if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi.ciAttributes
  actionName = node.workorder.rfcCi.rfcAction
else
  ci = node.workorder.ci.ciAttributes
  actionName = node.workorder.actionName
end

solrcloud_ci = node.workorder.payLoad.SolrCloudPayload[0].ciAttributes
setZkhostfqdn(solrcloud_ci['zk_select'], solrcloud_ci)

username = node['solr']['user']
collection_name = node['collection_name']

#delete the backup job
cron "#{username}-backup-#{collection_name}" do
  user username
  action :delete
end

#in case of delete action, delete existing backup job if exists and don't create new job
if actionName !~ /add|update|replace/
  Chef::Log.info("No add/update/replace action, hence existing backup job deleted if exists and no new job will be created")
  return
end

backup_enabled = (ci.has_key?('backup_enabled') && ci[:backup_enabled] == 'true')? true : false
Chef::Log.info("backup_enabled => #{backup_enabled}")
backup_location = ci['backup_location']
puts "backup_location = #{backup_location}"
#cron = "*/10 * * * 1"
cron = ci['backup_cron'] 
if backup_enabled
  if backup_location == nil || backup_location.empty?
    raise "If backup enabled, backup location must be provided."
  end
  if cron == nil || cron.empty?
    raise "If backup enabled, backup schedule must be provided."
  end
end
user_dir = node['user']['dir'] 
solr_backup_dir = "#{user_dir}/solr_backup"
solr_pack_dir = "#{user_dir}/solr_pack"
Chef::Log.info("user home directory : #{user_dir}")
directory solr_backup_dir do
  owner username
  group username
  mode '0755'
  action :create
  not_if{::File.exists?(solr_backup_dir)}
end

template "#{solr_pack_dir}/xmldiffs.py" do
  source 'xmldiffs.py'
  owner node['solr']['user']
  group node['solr']['user']
  mode '0777'
  mode '0777'
  not_if { ::File.exists?("#{solr_pack_dir}/xmldiffs.py") }
end

template "#{solr_pack_dir}/backup_collection_core.rb" do
  source "backup_collection_core.rb.erb"
  owner node['solr']['user']
  group node['solr']['user']
  mode "0755"
  variables({
        :solr_port_no => node['port_num'],
        :solr_host => node['ipaddress'],
        :number_to_keep => ci['backup_number_to_keep'],
        :backup_log_dir => "#{node['user']['dir']}/solrdata#{node['solrmajorversion']}/logs",
        :zk_host_fqdns => node['zk_host_fqdns'],
        :config_name => node['config_name'],
        :solr_lib_path => "#{node['user']['dir']}/solr-war-lib#{node['solrmajorversion']}"
  })
end

min, hour, day_of_month, month, day_of_week = cron.split

cmd = "ruby #{solr_pack_dir}/backup_collection_core.rb #{collection_name} #{backup_location}"
Chef::Log.info("command = #{cmd}")

cron "#{username}-backup-#{collection_name}" do
  minute min
  hour hour
  day day_of_month
  month month
  weekday day_of_week
  command cmd
  user username
  action :create
  only_if { backup_enabled }
end