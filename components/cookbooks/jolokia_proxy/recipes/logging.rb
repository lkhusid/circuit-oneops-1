#Configure log4j logging

directory "#{node[:jolokia_proxy][:lib_dir]}/ext" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
  action :create
end


remote_file "#{node[:jolokia_proxy][:lib_dir]}/ext/log4j-1.2.17.jar" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  source node.jolokia_proxy[:jolokia_log4j_location]
  action :create
end

remote_file "#{node[:jolokia_proxy][:lib_dir]}/ext/slf4j-api-1.7.21.jar" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  source node.jolokia_proxy[:jolokia_slf4j_api_location]
  action :create
end

remote_file "#{node[:jolokia_proxy][:lib_dir]}/ext/slf4j-log4j12-1.7.21.jar" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  source node.jolokia_proxy[:jolokia_slf4j_location]
  action :create
end

directory "#{node[:jolokia_proxy][:jetty_logs_dir]}" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
  action :create

end


directory "#{node[:jolokia_proxy][:requestlog_logs_dir]}" do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
  action :create

end


#copy log4j to  jetty.base/resource folder

#template "#{node[:jolokia_proxy][:conf_dir]}/jetty-logging.xml" do
#  source "jetty-logging.xml.erb"
#  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
#  action :create
#  notifies :restart, "service[jolokia_proxy]"
#end


# change default jetty-requestlogging.xml location
template "#{node[:jolokia_proxy][:conf_dir]}/jetty-requestlog.xml" do
  source "jetty-requestlog.xml.erb"
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  action :create
  notifies :restart, "service[jolokia_proxy]"
end

#copy log4j to  jetty.base/resource folder

template "#{node[:jolokia_proxy][:resources_dir]}/jetty-logging.properties" do
  source "jetty-logging.properties.erb"
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  action :create
  notifies :restart, "service[jolokia_proxy]"
end


template "#{node[:jolokia_proxy][:resources_dir]}/log4j.xml" do
  source "log4j.xml.erb"
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0644
  action :create
  notifies :restart, "service[jolokia_proxy]"
end
