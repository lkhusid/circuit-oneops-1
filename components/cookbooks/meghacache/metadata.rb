name             'Meghacache'
description      'MeghaCache'
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => [ 'bom' ]

attribute 'graphite_logfiles_path',
            :description => 'Graphite Metrics Tool Logfiles Path',
            :required => 'required',
            :default => '/opt/meghacache/log/graphite/graphite_stats.log',
            :format => {
                :help => 'Directory for graphite metrics tool logs',
                :category => '1.Global',
                :order => 1,
                :editable => false
            }

attribute 'graphite_prefix',
            :description => 'Graphite Prefix',
            :default => 'Meghacache',
            :format => {
                :help => 'Graphite prefix for data collection objects',
                :category => '1.Global',
                :order => 2
            }

attribute 'graphite_servers',
            :description => 'Graphite Servers',
            :data_type => 'array',
            :default => '[]',
            :format => {
                :help => 'Graphite servers to push metrics to. Provide server:port combinations. Example: localhost:2003',
                :category => '1.Global',
                :order => 3,
                :pattern => '[\S]+:[0-9]+'
            }
