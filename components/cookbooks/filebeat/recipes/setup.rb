# Cookbook Name:: filebeat
# Recipe:: setup.rb
#
# Copyright 2014, @WalmartLabs
#
# All rights reserved - Do Not Redistribute




configure = node['filebeat']['configure']
#configfile = node.workorder.rfcCi.ciAttributes.configfile
configdir = node['filebeat']['configdir']
name = node.workorder.payLoad.RealizedAs[0].ciName
user = "filebeat"
group = "filebeat"

if node['filebeat']['run_as_root'] == 'true'
  user = "root"
  group = "root"
end

filebeat_conf_variables = {
   :configure => configure,
}


filebeat_cmd_variables = {
   :configdir => configdir,
   :name => name,
   :user => user,
   :group => group
}

if(configure.nil? || configure.empty?)
   Chef::Log.info("config is empty, use default")
   execute 'Copying filebeat config file' do
    command "cp /etc/filebeat/filebeat.yml  /tmp/#{name}.1"
   end
else
  # generate conf file for filebeat
  template "/tmp/#{name}.1" do
      source "filebeat.yml.erb"
      owner #{user}
      group #{group}
      mode  '0664'
      variables filebeat_conf_variables
  end
end

# create the conf  dir
directory "#{configdir}" do
    owner #{user}
    group #{group}
    recursive true
    mode '0755'
    action :create
end

#  run the template engine
execute 'Running Template' do
    user #{user}
    command "source /etc/profile.d/oneops.sh;/usr/bin/config_template  /tmp/#{name}.1 > /tmp/#{name}.yml"
end
execute 'Copying filebeat config file' do
    command "cp /tmp/#{name}.yml  #{configdir}/#{name}.yml"
end

Chef::Log.info("DEBUG-enable test=" + node['filebeat']['enable_test'])

if node['filebeat']['enable_test'] == 'true'
  Chef::Log.info("DEBUG- Running Test")
  execute "Running test" do
    command "/usr/bin/filebeat -configtest -N -c #{configdir}/#{name}.yml" 
  end
end

initd_filename = 'filebeat'
if(name.empty? || name.nil?)
  Chef::Log.info("instance name is not set. use default.")
else 
  initd_filename = initd_filename + "_" + name
end

template "/etc/init.d/#{initd_filename}" do
  source "initd.erb"
  owner #{user}
  group #{group}
  mode 0755
  variables filebeat_cmd_variables
end

directory "/var/lib/filebeat" do
    owner #{user}
    group #{group}
    recursive true
    mode '0755'
    action :create
end

execute "chmod for /var/log/yum.log" do
  command "chmod 766 /var/log/yum.log"
end

     






