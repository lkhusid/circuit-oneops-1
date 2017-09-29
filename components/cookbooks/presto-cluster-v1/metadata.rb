name             'Presto-cluster-v1'
maintainer       '@WalmartLabs'
maintainer_email 'paas@email.wal-mart.com'
license          'All rights reserved'
description      'Presto cluster component (V1 build)'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'

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
    :category => '1.Operations',
    :order => 1
  }

# Actions
#recipe "repair", "Repair the Cluster"
