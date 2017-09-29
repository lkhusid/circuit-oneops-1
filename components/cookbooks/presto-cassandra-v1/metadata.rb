name             'Presto-cassandra-v1'
maintainer       'Walmart Labs'
maintainer_email 'paas@email.wal-mart.com'
license          'Apache License, Version 2.0'
description      'Presto Cassandra Connector (V1 Build)'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'
depends          'shared'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

# installation attributes

attribute 'connection_name',
          :description => 'Cassandra Conenction Name',
          :required => 'required',
          :default => 'myconnectionname',
          :format => {
              :category => '1.Global',
              :help => 'Name of connection for Cassandra',
              :order => 1
          }

attribute 'connection_contact_points',
        :description => 'Cassandra Contact Points',
        :required => 'required',
        :default => 'host1,host2',
        :format => {
            :category => '1.Global',
            :help => 'Contact hosts for Cassandra',
            :order => 2
        }

attribute 'connector_config',
          :description => 'Connector Configuration',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Configuration values to add to the connector configuration',
              :category => '1.Global',
              :order => 3
          }
