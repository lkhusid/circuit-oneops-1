name             'Presto-swift-v2'
maintainer       'Walmart Labs'
maintainer_email 'paas@email.wal-mart.com'
license          'Apache License, Version 2.0'
description      'Presto Swift Connector'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.0'
depends          'shared'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

# installation attributes

attribute 'connection_name',
          :description => 'Swift Connection Name',
          :required => 'required',
          :default => 'object_store',
          :format => {
              :category => '1.Global',
              :help => 'Name of connection for Swift',
              :order => 1
          }

attribute 'connector_config',
          :description => 'Connector Configuration',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Configuration values to add to the connector configuration',
              :category => '1.Global',
              :order => 2
          }
