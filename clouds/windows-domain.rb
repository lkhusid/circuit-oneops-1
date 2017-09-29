name "windows-domain"
description "Membership in windows domain"
auth "windowsdomainsecretkey"

service "windows-domain-public",
  :cookbook => 'windows-domain',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'windows-domain' }
