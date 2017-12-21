#Create Mcrouter Dir
[
    '/etc/mcrouter',
    File.dirname(node['mcrouter']['pid-file']),
    File.dirname(node['mcrouter']['log-path']),
    node['mcrouter']['async-dir'],
    node['mcrouter']['stats-root']
].each do |dir|
  directory dir do
    owner node['mcrouter']['user']
    group node['mcrouter']['user']
    recursive true
  end
end

file node['mcrouter']['config-file'] do
  content "#{McrouterRouteConfig.get_mcrouter_cloud_config(node)}"
  owner node['mcrouter']['user']
  group node['mcrouter']['user']
end
