#include_recipe "kafka_rest::validate_input"

version=node['kafka_rest'][:version]

cloud = node.workorder.cloud.ciName
mirror_url_key = "kafkarest"
Chef::Log.info("Getting mirror service for #{mirror_url_key}, cloud: #{cloud}")

mirror_svc = node[:workorder][:services][:mirror]
mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors]) if !mirror_svc.nil?
base_url = ''

# Search for Kafka mirror
base_url = mirror[mirror_url_key] if !mirror.nil? && mirror.has_key?(mirror_url_key)

if base_url.empty?
  Chef::Log.error("#{mirror_url_key} mirror is empty for #{cloud}.")
end

file_name="confluent-kafka-rest-#{version}.tar.gz"
tarball = "#{version}/#{file_name}"

remote_file "#{Chef::Config[:file_cache_path]}/#{file_name}" do
  source "#{base_url}/#{tarball}"
  mode '0644'
  action :create
end

execute 'extract rpm from tar' do
  cwd Chef::Config[:file_cache_path]
  command "tar xvf #{file_name}"
end

node['kafka_rest'][node['kafka_rest'][:version]]['packages'].each do |package|
  name_file = package.split(":")
  name = name_file[0]
  file = name_file[1]
  package "#{name}" do
    source "#{Chef::Config[:file_cache_path]}/#{file}"
    action :install
  end
end

template '/etc/kafka-rest/kafka-rest.properties' do
  source 'kafka-rest.properties.erb'
  variables ({
  	:ssl_properties => setup_ssl_get_props()
  })
end

template '/etc/kafka-rest/log4j.properties' do
  source 'log4j.properties.erb'
end

directory "#{node['kafka_rest'][:log_dir]}" do
  action :create
  owner "#{node['kafka_rest'][:user]}"
  group "#{node['kafka_rest'][:group]}"
end

template '/etc/init.d/kafka-rest' do
  source 'kafka-rest.erb'
  mode '0755'
  action :create
end

bash 'add jmx rmi port' do
  code <<-EOH
    sudo su
    sed -i 's#KAFKAREST_JMX_OPTS="$KAFKAREST_JMX_OPTS -Dcom.sun.management.jmxremote.port=$JMX_PORT "#KAFKAREST_JMX_OPTS="$KAFKAREST_JMX_OPTS -Dcom.sun.management.jmxremote.port=$JMX_PORT -Dcom.sun.management.jmxremote.rmi.port=$(($JMX_PORT+1)) "#g' /usr/bin/kafka-rest-run-class
  EOH
end

execute 'kafka-rest' do
  command "sudo service kafka-rest restart"
end
