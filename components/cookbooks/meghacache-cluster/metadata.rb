name             'Meghacache-cluster'
description      'MeghaCache Cluster'
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

attribute 'dns_record',
          :description => "DNS Record value used by FQDN",
          :grouping => 'bom',
          :format => {
              :important => true,
              :help => 'DNS Record value used by FQDN',
              :category => '1.Global',
              :order => 2
          }
