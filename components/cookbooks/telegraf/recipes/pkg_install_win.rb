if node['platform_family'] != 'windows'
  return
end

mirror_svc = node[:workorder][:services][:mirror]
config_file_path = 'c:\\program files\\telegraf\\telegraf.conf'
oneops_conf_path = 'c:\\etc\\profile.d\\oneops.conf'
configure = node['telegraf']['configure']
broker_address = ''
mirror_pkg_source_url = ''
dc = ''

Chef::Log.info("mirror service repo: #{mirror_pkg_source_url}")
Chef::Log.info("Installing telegraf using choco...")

if !mirror_svc.nil?
  cloud = node.workorder.cloud.ciName
  mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors])
  mirror_pkg_source_url = mirror['chocorepo']
else
  msg = 'Mirror service required for telegraf'
  puts"***FAULT:FATAL=#{msg}"
  e=Exception.new("#{msg}")
  e.set_backtrace('')
  raise e
end

chocolatey_package "telegraf" do
  source mirror_pkg_source_url unless (mirror_pkg_source_url.nil? || mirror_pkg_source_url.empty?)
  options "--ignore-package-exit-codes=3010"
  action :install
end

Chef::Log.info("Setting the windows envs from #{oneops_conf_path}")

File.readlines(oneops_conf_path).each do |line|
  key = line.split("=")[0].strip
  val = line.split("=")[1].strip
  env key do
    value val
  end
  if (key == 'DATACENTER')
    dc = val
  end
end

broker_address = mirror["#{dc}_kafka_broker"]
if (broker_address.nil?)
  broker_address = mirror["default_kafka_broker"]
end

broker_address = broker_address.split(",").map { |e| "'#{e}'" }.join(',')

Chef::Log.info("Using kafka broker address for telegraf if available: [#{broker_address}]")

configure = configure.gsub("%kafka_endpoint_address%",broker_address)

file config_file_path do
  content configure
  action :create
end

if node['telegraf']['enable_agent'] == 'true'
  Chef::Log.info("DEBUG-starting...")
  include_recipe "telegraf::start"
end
