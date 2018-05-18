# McRouter Command Line Options
# Base CLI opts
ci=node['mcrouter']

cli_opts = [
    "--port=#{ci['port']}",
    "--config=file:#{ci['config-file']}",
    "--stats-root=#{ci['stats-root']}",
]

# Optional CLI opts

if ci.has_key?('enable_asynclog') && ci['enable_asynclog'] == 'false'
  cli_opts.push("--asynclog-disable")
else
  cli_opts.push("--async-dir=#{ci['async-dir']}")
end

if ci.has_key?('enable_flush_cmd') && ci['enable_flush_cmd'] == 'true'
  cli_opts.push("--enable-flush-cmd")
end

if ci.has_key?('enable_logging_route') && ci['enable_logging_route'] == 'true'
  cli_opts.push("--enable-logging-route")
end

if ci.has_key?('num_proxies')
  cli_opts.push("--num-proxies=#{ci['num_proxies']}")
end

if ci.has_key?('server_timeout')
  cli_opts.push("--server-timeout=#{ci['server_timeout']}")
end

if ci.has_key?('verbosity') && ci['verbosity'] != 'disabled'
  cli_opts.push("--verbosity=#{ci['verbosity']}")
end

if ci.has_key?('additional_cli_opts')
  JSON.parse(ci['additional_cli_opts']).each do |opt|
    cli_opts.push(opt) 
  end
end

template "mcrouter_service" do
  path "/usr/lib/systemd/system/mcrouter.service"
  source "mcrouter.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
      :cli_opts => cli_opts,
      :mcrouter_user => ci['user'],
      :pid_file => ci['pid-file'],
      :install_dir => ci['install_dir']
  )
end

template "/etc/logrotate.d/mcrouter-async" do
  source "logrotate.erb"
  mode "0644"
  variables(
      :async_dir => node['mcrouter']['async-dir']
  )
end

cron "logrotate" do
  minute '0'
  command "sudo /usr/sbin/logrotate /etc/logrotate.d/mcrouter-async"
  mailto '/dev/null'
  action :create
end

execute "systemctl daemon-reload"
execute "systemctl enable mcrouter.service"
execute "systemctl start mcrouter.service"
