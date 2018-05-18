ci=node['memcached']
  
cli_opts=[
  "-U 0", # Disabled UDP
  "-u #{ci[:user]}",
  "-p #{ci[:port]}",
  "-m #{ci['max_memory']}",
  "-c #{ci['max_connections']}",
  "-l #{ci['ipaddress']}",
]

if ci.has_key?("log_level")
  case ci["log_level"]
    when 'disabled'
      # do nothing
    when 'verbose'
      cli_opts.push('-v')
    when 'very_verbose'
      cli_opts.push('-vv')
    when 'extremely_verbose'
      cli_opts.push('-vvv')  
  end
end

if ci.has_key?('enable_cas') && ci['enable_cas'] == "false"
  cli_opts.push("-C")
end

if ci.has_key?('enable_error_on_memory_ex') && ci['enable_error_on_memory_ex'] == "true"
  cli_opts.push("-M")
end

if ci.has_key?('num_threads')
  cli_opts.push("-t #{ci['num_threads']}");
end
        
if ci.has_key?('additional_cli_opts')
  JSON.parse(ci['additional_cli_opts']).each do |opt|
    cli_opts.push(opt) 
  end
end

directory '/opt/memcached/stats' do
    owner 'nagios'
    group 'root'
    mode '0755'
    recursive true
end

directory '/opt/memcached/lib' do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
end

template "memcached_service" do
    path "/usr/lib/systemd/system/memcached.service"
    source "memcached.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      :cli_opts => cli_opts,
      :memcached_user => ci['user']
    )
end

cookbook_file "/opt/memcached/lib/memcache_stats.rb" do
    source "memcache_stats.rb"
    owner 'root'
    group 'root'
    mode '0755'
end

template "/opt/nagios/libexec/check_memcached_stats.rb" do
    source "check_memcached_stats.rb.erb"
    owner "root"
    group "root"
    mode "0755"
end

package "libevent" do
  action :install
end

if ci['version'] == "repo"
  package "memcached" do
    action :install
  end
else

  pkg = PackageFinder.search_for(ci['base_url'], ci['package_name'], ci['version'], ci['arch'], ci['pkg_type'])

  # Get the url and filename from the package.
  if pkg.empty?
    Chef::Application.fatal!("Can't find the install package.")
  end
  url = pkg[0]
  file_name = pkg[1]
  
  Chef::Log.info("memcached rpm: #{url}")
  
  dl_file = ::File.join(Chef::Config[:file_cache_path], '/', file_name)
  
  # Download the package
  remote_file dl_file do
    source url
    action :create_if_missing
  end
  
  # Install the package
  package "#{ci['package_name']}-#{ci['version']}" do
    source dl_file
    provider Chef::Provider::Package::Rpm if ci['pkg_type'] == 'rpm'
    provider Chef::Provider::Package::Dpkg if ci['pkg_type'] == 'deb'
    action :install
  end
end

# Delete '/etc/init.d/memcached' from rpm install
file '/etc/init.d/memcached' do
  action :delete
  only_if {File.exists?('/etc/init.d/memcached')}
end

execute "systemctl daemon-reload"
execute "systemctl enable memcached.service"
execute "systemctl start memcached.service"
