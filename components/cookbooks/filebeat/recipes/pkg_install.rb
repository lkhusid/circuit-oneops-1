#
# Cookbook Name:: Filebeat
# Recipe:: pkg_install.rb
#
# Copyright 2015, @WalmartLabs
#
# All rights reserved - Do Not Redistribute

ci = node.workorder.has_key?("rfcCi") ? node.workorder.rfcCi : node.workorder.ci
filebeat_version = ci.ciAttributes.version



user "filebeat" do
  gid "nobody"
  shell "/bin/false"
end


user = "filebeat"
group = "filebeat"

if node['filebeat']['run_as_root'] == 'true'
  user = "root"
  group = "root"
end

cloud = node.workorder.cloud.ciName
mirror_url_key = "filebeat"
Chef::Log.info("Getting mirror service for #{mirror_url_key}, cloud: #{cloud}")

mirror_svc = node[:workorder][:services][:mirror]
mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors]) if !mirror_svc.nil?
base_url = ''

# Search for filebeat mirror
base_url = mirror[mirror_url_key] if !mirror.nil? && mirror.has_key?(mirror_url_key)

default_base_url ="http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/com/walmart/platform/filebeat/"
if base_url.empty?
    Chef::Log.error("#{mirror_url_key} mirror is empty for #{cloud}. Use default path:#{default_base_url}")
    base_url = default_base_url
end

Chef::Log.info("version=#{filebeat_version}")
#filebeat_rpm = "filebeat-#{filebeat_version}.rpm"
filebeat_tgz = "filebeat-#{filebeat_version}.tar.gz"
#filebeat_download_rpm = base_url + "#{filebeat_version}/#{filebeat_rpm}"
filebeat_download_tgz = base_url + "#{filebeat_version}/#{filebeat_tgz}"

Chef::Log.info("downloading #{filebeat_download_tgz} ...")
# download filebeat_tgz
remote_file ::File.join(Chef::Config[:file_cache_path], "#{filebeat_tgz}") do
    owner #{user}
    mode "0644"
    source filebeat_download_tgz
    action :create
end
Chef::Log.info("done")

Chef::Log.info("Installing #{filebeat_tgz} ...")
# install filebeat_tgz
execute 'install filebeat tgz' do
    #user "app"
    cwd Chef::Config[:file_cache_path]
    command "tar --strip-components=1 -C / -zxf  #{filebeat_tgz}"
end


# Search for jinja mirror
jinja_template_version = '4.1-1'

jinja_default_base_url = "http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty/com/walmartlabs/platform/jinja.template_config/#{jinja_template_version}/jinja.template_config-#{jinja_template_version}-x86_64.rpm"

jinja_mirror_url_key = "jinja-template"
jinja_base_url = ''
jinja_base_url = mirror[jinja_mirror_url_key] if !mirror.nil? && mirror.has_key?(jinja_mirror_url_key)

if jinja_base_url.empty?
    Chef::Log.error("#{jinja_mirror_url_key} mirror is empty for #{cloud}. Use default path:#{jinja_default_base_url}")
    jinja_base_url = jinja_default_base_url
end

Chef::Log.info("downloading #{jinja_base_url} ...")
remote_file ::File.join(Chef::Config[:file_cache_path], "jinja.template_config-#{jinja_template_version}-x86_64.rpm") do
    owner #{user}
    mode "0644"
    source jinja_base_url
    action :create
end

execute "Installing Template Engine" do
  command "rpm -Uvh --replacepkgs  /tmp/jinja.template_config-#{jinja_template_version}-x86_64.rpm"
end

Chef::Log.info("done mama")





# make sure /tmp is writable for everyone
bash "tmp-writable" do
    user "root"
    code <<-EOF
    (chmod a+rwx /tmp)
    EOF
end

