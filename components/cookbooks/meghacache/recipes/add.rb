include_recipe 'meghacache::performance_tuning'

check_meghacahe_process = '/opt/nagios/libexec/check_meghacache_process.sh'

execute "remove_old_file" do
  user 'root'
  command "rm #{check_meghacahe_process}"
  only_if {::File.exists?("#{check_meghacahe_process}") }
end

cch_old_file_monitor  = "/home/oneops/components/cookbooks/monitor/files/default/check_meghacahe_process.erb"
execute "remove_old_file_from_monitor" do
  user 'root'
  command "rm #{cch_old_file_monitor}"
  only_if {::File.exists?("#{cch_old_file_monitor}") }
end

template "#{check_meghacahe_process}" do
  source "check_meghacahe_process.erb"
  owner 'root'
  group 'root'
  mode "0755"
  action :create
end

[
    '/opt/meghacache/bin',
    '/opt/meghacache/lib',
    '/opt/meghacache/log/graphite',
    '/opt/meghacache/log/telegraf'
].each do |dirname|
    directory dirname do
      owner "root"
      group "root"
      mode "0755"
      recursive true
    end
end

cookbook_file "/opt/meghacache/lib/graphite_writer.rb" do
    source "graphite_writer.rb"
    owner 'root'
    group 'root'
    mode '0755'
end

cookbook_file "/opt/meghacache/lib/telegraf_writer.rb" do
    source "telegraf_writer.rb"
    owner 'root'
    group 'root'
    mode '0755'
end

cookbook_file "/opt/meghacache/lib/network_stats.rb" do
    source "network_stats.rb"
    owner 'root'
    group 'root'
    mode '0755'
end

file '/opt/meghacache/log/telegraf/stats.log' do
  content "# Logfile created on #{Time.now.to_s} by #{__FILE__}\n"
  owner 'root'
  group 'root'
  mode '0644'
  action :create_if_missing
  end

file '/opt/meghacache/log/telegraf/mcroutertko.log' do
  content "# Logfile created on #{Time.now.to_s} by #{__FILE__}\n"
  owner 'root'
  group 'root'
  mode '0644'
  action :create_if_missing
end

return_status = -1
return_status = deep_fetch(node, 'workorder', 'rfcCi', 'nsPath')

if return_status == 0 then

    Chef::Log.info "return_status = #{return_status}"
    ns_path = node.workorder.rfcCi.nsPath.split(/\//)
    oo_org=ns_path[1]
    oo_assembly=ns_path[2]
    oo_env=ns_path[3]
    oo_platform=ns_path[5]
    oo_cloud=node.workorder.cloud.ciName

end

if  deep_fetch(node, 'workorder', 'payLoad', 'memcached.first', 'ciAttributes', 'port') == 0 &&
    deep_fetch(node, 'meghacache', 'graphite_logfiles_path') == 0 &&
    deep_fetch(node, 'meghacache', 'graphite_servers') == 0 &&
    deep_fetch(node, 'meghacache', 'graphite_prefix') == 0 &&
    deep_fetch(node, 'workorder', 'cloud', 'ciId') == 0 then

    memcached_port = node.workorder.payLoad.memcached.first.ciAttributes.port
    graphite_logfiles_path = node.meghacache.graphite_logfiles_path
    graphite_servers = node.meghacache.graphite_servers
    graphite_prefix = node.meghacache.graphite_prefix
    current_cloud_id = node.workorder.cloud['ciId']

    template "/opt/meghacache/bin/collect_graphite_stats.rb" do
        source "collect_graphite_stats.rb.erb"
        owner "root"
        group "root"
        mode "0755"
        variables({
                    :graphite_servers => graphite_servers,
                    :graphite_prefix => graphite_prefix,
                    :graphite_logfiles_path => graphite_logfiles_path,
                    :memcached_port => memcached_port,
                    :mcrouter_port => 5000,
                    :oo_org => oo_org,
                    :oo_assembly => oo_assembly,
                    :oo_env => oo_env,
                    :oo_platform => oo_platform,
                    :oo_cloud => oo_cloud,
                    :current_cloud_id => current_cloud_id
                })
    end

    cron "collect_graphite_stats" do
      user 'root'
      minute "*/1"
      command "sudo /bin/ruby /opt/meghacache/bin/collect_graphite_stats.rb 2>&1 | /bin/logger"
      only_if { ::File.exists?("/opt/meghacache/bin/collect_graphite_stats.rb") }
    end

    template "mcrouter_mon.rb" do
        path "/opt/meghacache/lib/mcrouter_mon.rb"
        source "mcrouter_mon.rb.erb"
        owner "root"
        group "root"
        mode "0755"
        variables({
                  :graphite_servers => graphite_servers,
                  :graphite_prefix => graphite_prefix,
                  :graphite_logfiles_path => graphite_logfiles_path,
                  :oo_org => oo_org,
                  :oo_assembly => oo_assembly,
                  :oo_env => oo_env,
                  :oo_platform => oo_platform,
                  :oo_cloud => oo_cloud
                  })
    end

    template "mcrouter_mon.service" do
        path "/usr/lib/systemd/system/mcrouter_mon.service"
        source "mcrouter_mon.service.erb"
        owner "root"
        group "root"
        mode "0644"
        variables(
           :mcrouter_mon_path => "/opt/meghacache/lib/mcrouter_mon.rb"
        )
    end

else
    Chef::Log.warn "WARNING: Unable to deploy Graphite stats collection cron job"
end

execute "systemctl daemon-reload"
execute "systemctl enable mcrouter_mon.service"
execute "systemctl restart mcrouter_mon.service"
