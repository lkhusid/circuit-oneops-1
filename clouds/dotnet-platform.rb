name 'dotnet-platform'
description 'dotnet platform services'


service "dotnet-platform-public",
  :cookbook => 'dotnet-platform',
  :ignore => true,
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'dotnet-platform' }
