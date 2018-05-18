#
# Cookbook Name:: jolokia_proxy
#
#

##Get apache mirror configured for the cloud, if no mirror is defined for component.
cloud_name = node[:workorder][:cloud][:ciName]
services = node[:workorder][:services]
if services.nil? || !services.has_key?(:mirror)
  Chef::Log.error("Please make sure  cloud '#{cloud_name}' has mirror service with 'eclipse' eg {eclipse=>http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/}")
  exit 1
end
mirrors = JSON.parse(services[:mirror][cloud_name][:ciAttributes][:mirrors])

if mirrors.nil? || !mirrors.has_key?('jetty')
  Chef::Log.error("Please make sure  cloud '#{cloud_name}' has mirror service with 'eclipse' eg {eclipse=>http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/}")
  exit 1
end

node.override[:jolokia_proxy][:mirror]=mirrors['jetty']
node.override[:jolokia_proxy][:jolokia_war_mirror]=mirrors['jolokia-war']

node.override[:jolokia_proxy][:jolokia_log4j_location]=mirrors['jolokia-log4j']
node.override[:jolokia_proxy][:jolokia_slf4j_location]=mirrors['jolokia-slf4j']
node.override[:jolokia_proxy][:jolokia_slf4j_api_location]=mirrors['jolokia-slf4j-api']

node.override[:jolokia_proxy][:jetty_download_location]="#{node[:jolokia_proxy][:mirror]}/#{node[:jolokia_proxy][:version]}/#{node[:jolokia_proxy][:tgz_file]}"

jetty_download_location="#{node[:jolokia_proxy][:jetty_download_location]}"
jetty_untar_dir_name = "#{node[:jolokia_proxy][:untar_dir]}"
tgz_file="#{node[:jolokia_proxy][:tgz_file]}"

#jolokia war location
jolokia_war_location="#{node[:jolokia_proxy][:jolokia_war_mirror]}/#{node[:jolokia_proxy][:jolokia_war_version]}/#{node[:jolokia_proxy][:jolokia_war_file]}"

#read vauables from meta.rb


node.override[:jolokia_proxy][:user] = node.workorder.rfcCi.ciAttributes.jolokia_proxy_process_user
node.override[:jolokia_proxy][:group] = node.workorder.rfcCi.ciAttributes.jolokia_proxy_process_user
  
node.override[:jolokia_proxy][:java_options]= node.workorder.rfcCi.ciAttributes.jvm_parameters

node.default[:proxy_user] = node.workorder.rfcCi.ciAttributes.jolokia_proxy_process_user
#check if user exists on the system, or error out
  

if Jolokia_proxy::Util.sudo_user(node[:proxy_user]) == false
      Chef::Log.error("User #{node[:proxy_user]} doesn't exists on the system. Please create this user first")
    else 
      Chef::Log.info("User #{node[:proxy_user]} exists on the system.")
  end

node.override[:jolokia_proxy][:jetty_logs_dir] = node.workorder.rfcCi.ciAttributes.log_location
node.override[:jolokia_proxy][:requestlog_logs_dir] = node.workorder.rfcCi.ciAttributes.request_log_location
node.override[:jolokia_proxy][:version] = node.workorder.rfcCi.ciAttributes.version
node.override[:jolokia_proxy][:jolokia_war_version] = node.workorder.rfcCi.ciAttributes.jolokia_war_version
node.override[:jolokia_proxy][:log_level] = node.workorder.rfcCi.ciAttributes.log_level
node.override[:jolokia_proxy][:request_log_retaindays] = node.workorder.rfcCi.ciAttributes.request_log_retaindays
node.override[:jolokia_proxy][:bind_host] = node.workorder.rfcCi.ciAttributes.bind_host
node.override[:jolokia_proxy][:bind_port] = node.workorder.rfcCi.ciAttributes.bind_port
node.override[:jolokia_proxy][:args]=["-Djetty.http.host="+node.workorder.rfcCi.ciAttributes.bind_host,"-Djetty.http.port="+node.workorder.rfcCi.ciAttributes.bind_port]

node.override[:jolokia_proxy][:enable_requestlog_logging] =node.workorder.rfcCi.ciAttributes.enable_requestlog_logging
enable_requestlog_logging=node.workorder.rfcCi.ciAttributes.enable_requestlog_logging

node.default[:jetty_log_max_filesize]=node.workorder.rfcCi.ciAttributes.jetty_log_max_filesize
node.default[:jetty_log_backup_index]=node.workorder.rfcCi.ciAttributes.jetty_log_backup_index




Chef::Log.info("RequestLog Logging set to  #{enable_requestlog_logging}")

if enable_requestlog_logging == "true"
node.override[:jolokia_proxy][:add_confs]=["#{node.jolokia_proxy[:conf_dir]}/jetty-requestlog.xml"]
else
 node.override[:jolokia_proxy][:add_confs]=[]
end  
  
#"-Dorg.eclipse.jetty.util.log.class=org.eclipse.jetty.util.log.Slf4jLog"
Chef::Log.info("Starting parameters for Jetty #{node.jolokia_proxy[:add_confs]}")
  
  


# Create service
#
template "/etc/init.d/jolokia_proxy" do
  source "jetty9-init.sh.erb"
  owner 'root' and group 'root' and mode 0755
end

service "jolokia_proxy" do
# supports :status => true, :restart => true, :start => true, :stop => true
  action [ :stop ]
end



Chef::Log.info("download locaction #{jetty_download_location}  war location #{jolokia_war_location}")

remote_file "/tmp/#{tgz_file}" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  source jetty_download_location
  checksum node[:jolokia_proxy][:checksum]
  action :create
end

# 
['home_dir' , 'jetty_base_dir', 'pid_dir' ].each { |dir|
  dir_name = node[:jolokia_proxy][dir]
  Chef::Log.info("creating base #{dir} for jolokia")
  directory dir_name do
    not_if { ::File.directory?(dir_name) }
    owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
   
    recursive true
  end
}



jetty_dir="#{node[:jolokia_proxy][:home_dir]}/#{jetty_untar_dir_name}"
execute 'install jetty' do
    user node.jolokia_proxy[:user] 
    group node.jolokia_proxy[:group]
    cwd  "#{node[:jolokia_proxy][:home_dir]}"
    Chef::Log.info "Extracting Jetty archive"
    command "tar -zxf /tmp/#{tgz_file}; rm -fr jetty ; ln -sf #{jetty_untar_dir_name} jetty_home"
    only_if { !File.exists?(jetty_dir) }
 end
#end
 

directory "#{jetty_dir}" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
  action :create
  recursive true
end
 
 
#Create dir for jetty base

['conf_dir' , 'lib_dir', 'resources_dir' , 'webapps_dir'].each { |dir|
  proxy_dir_name = node[:jolokia_proxy][dir]
  Chef::Log.info("creating #{proxy_dir_name} for proxy base")
  directory proxy_dir_name do
    not_if { ::File.directory?(proxy_dir_name) }
    owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
    recursive true
  end
}


directory "#{node[:jolokia_proxy][:lib_dir]}/jolokia" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
  action :create
  
end


include_recipe "jolokia_proxy::logging"



#copy war file for jolokia from repo to webapp folder
remote_file "#{node[:jolokia_proxy][:lib_dir]}/jolokia/jolokia.war" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  source jolokia_war_location
  checksum node[:jolokia_proxy][:jolokia_war_checksum]
  action :create
end


template '/etc/default/jetty' do
  source 'jetty.default.erb'
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  action :create
  #notifies :restart, "service[jolokia_proxy]"
end


template "/etc/jetty.conf" do
  source "jetty.conf.erb"
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  action :create
 # notifies :restart, "service[jolokia_proxy]"
end

#copy start.ini to jetty.base folder

template "#{node[:jolokia_proxy][:jetty_base_dir]}/start.ini" do
  source "start.ini.erb"
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  action :create
 # notifies :restart, "service[jolokia_proxy]"
end


execute "Change ownership of home and log dir" do
  command "chown -R #{node[:proxy_user]}:#{node[:proxy_user]} #{node.jolokia_proxy[:home_dir]}"
  #chown -R #{node[:proxy_user]}:#{node[:proxy_user]} #{node.jolokia_proxy[:jetty_logs_dir]}
end


#Enable/Diasable Jolokia_proxy component.
enable_jolokia_proxy=node.workorder.rfcCi.ciAttributes.enable_jolokia_proxy
Chef::Log.info("Enable/Disable Flag is set to  #{enable_jolokia_proxy}")

if enable_jolokia_proxy == "true"
  include_recipe "jolokia_proxy::start"
else
  include_recipe "jolokia_proxy::stop"
end  
  

  