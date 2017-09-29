include_recipe "tomcat::generate_variables"

tomcat_version_name = node['tomcat']['tomcat_version_name']

#Ignore foodcritic(FC024) warnings.  We only have a subset of OSes available
service "tomcat" do
  only_if { File.exists?('/etc/init.d/' + tomcat_version_name) }
  service_name tomcat_version_name
  case node["platform"]
  when "centos","redhat","fedora" # ~FC024
    supports :restart => true, :status => true
  when "debian","ubuntu"
    supports :restart => true, :reload => true, :status => true
  end
end

include_recipe "tomcat::stop"

if ( node.workorder.rfcCi.ciBaseAttributes.has_key?("version") &&
   node.workorder.rfcCi.ciBaseAttributes["version"] != node.tomcat.version )
  include_recipe "tomcat::cleanup"
end

include_recipe "tomcat::add_binary"

template "/etc/logrotate.d/tomcat" do
  source "logrotate.erb"
  owner "root"
  group "root"
  mode "0755"
end

cron "logrotatecleanup" do
  minute '0'
  command "ls -t1 #{node.tomcat.access_log_dir}/access_log*|tail -n +7|xargs rm -r"
  mailto '/dev/null'
  action :create
end

cron "logrotate" do
  minute '0'
  command "sudo /usr/sbin/logrotate /etc/logrotate.d/tomcat"
  mailto '/dev/null'
  action :create
end

depends_on_keystore=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Keystore/ }

template "/opt/nagios/libexec/check_tomcat.rb" do
  source "check_tomcat.rb.erb"
  owner "oneops"
  group "oneops"
  mode "0755"
end

template "/opt/nagios/libexec/check_ecv.rb" do
  source "check_ecv.rb.erb"
  owner "oneops"
  group "oneops"
  mode "0755"
end

include_recipe 'tomcat::versionstatus'
template "/opt/nagios/libexec/check_tomcat_app_version.sh" do
  source "check_tomcat_app_version.sh.erb"
   variables({
     :versioncheckscript => node['versioncheckscript'],
    });
  owner "oneops"
  group "oneops"
  mode "0755"
end

['webapp_install_dir','log_dir','work_dir','context_dir','webapp_dir'].each do |dir|
  dir_name = node['tomcat'][dir]
  directory dir_name do
    action :create
    recursive true
    not_if "test -d #{dir_name}"
  end
  execute "chown -R #{node.tomcat_owner}:#{node.tomcat_group} #{dir_name}"
  execute "chmod -R 0755 #{dir_name}"
end

link node['tomcat']['webapp_install_dir'] do
  to node['tomcat']['webapp_dir']
  owner node.tomcat_owner
  group node.tomcat_group
  action :create
  not_if "test -d #{node['tomcat']['webapp_install_dir']}"
end

service "tomcat" do
  service_name tom_ver
	action [:enable]
end
include_recipe "tomcat::restart"
