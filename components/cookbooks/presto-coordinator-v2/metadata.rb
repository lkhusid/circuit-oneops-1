name             'Presto-coordinator-v2'
maintainer       'Walmart Labs'
maintainer_email 'paas@email.wal-mart.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures presto'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.0'
depends          'shared'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'include_coordinator',
       :description => 'Include Coordinator',
       :required => 'required',
       :default  => 'true',
       :format  => {
           :important  => true,
           :help  => 'Allow scheduling of work on the coordinator.',
           :category  => '1.Global',
           :order  => 1
       }

recipe 'status', 'Presto Coordinator Status'
recipe 'select_new_coordinator', 'Select New Presto Coordinator'
