
configName = node['app_name']
configNode = node[configName]

presto_pkgs = value_for_platform(
  "default" => ["presto-server-rpm"]
)

include_recipe "#{node['app_name']}::stop"

presto_pkgs.each do |pkg|
  package pkg do
    action :purge
  end
end



directory "/etc/presto" do
  recursive true
  action :delete
end

directory configNode['data_directory_dir'] do
  recursive true
  action :delete
end

directory "/usr/lib/presto/var" do
  recursive true
  action :delete
end
