name "centrifydc-vb1"
description "CentrifyDC Service (Beta 1 Build)"
auth "cdcsecret"
#ignore true

service 'centrifydc-vb1',
  :description => 'Centrify Service',
  :cookbook => 'centrifydc-vb1',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => {:service => 'centrify'},
  :attributes => { }

