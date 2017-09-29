template '/opt/nagios/libexec/sql_servicemonitor.ps1' do
  cookbook 'mssql'
  source 'sql_servicemonitor.ps1.erb'
  owner 'oneops'
  group 'oneops'
  mode '0777'
end

template '/opt/nagios/libexec/sql_dbcount.ps1' do
  cookbook 'mssql'
  source 'sql_dbcount.ps1.erb'
  owner 'oneops'
  group 'oneops'
  mode '0777'
end

template '/opt/nagios/libexec/sql_disklatency.ps1' do
  cookbook 'mssql'
  source 'sql_disklatency.ps1.erb'
  owner 'oneops'
  group 'oneops'
  mode '0777'
end
