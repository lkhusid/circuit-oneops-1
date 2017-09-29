name             'Presto-mysql-v2'
maintainer       'Walmart Labs'
maintainer_email 'paas@email.wal-mart.com'
license          'Apache License, Version 2.0'
description      'Presto MySQL Connector'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.0.0'
depends          'shared'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

# installation attributes

attribute 'connection_name',
          :description => 'MySQL Conenction Name',
          :required => 'required',
          :default => 'myconnectionname',
          :format => {
              :category => '1.Global',
              :help => 'Name of connection for MySQL',
              :order => 1
          }

attribute 'connection_url',
        :description => 'MySQL Conenction URL',
        :required => 'required',
        :default => 'jdbc:mysql://example.net:3306',
        :format => {
            :category => '1.Global',
            :help => 'Connection URL to connect to MySQL',
            :order => 2
        }

attribute 'connection_user_id',
          :description => 'MySQL User Id',
          :required => 'required',
          :default => 'someuserid',
          :format => {
              :category => '1.Global',
              :help => 'UserId to connect to MySQL',
              :order => 3
          }

attribute 'connection_password',
        :description => 'MySQL password',
        :required => 'required',
        :encrypted => true,
        :default => 'somepassword',
        :format => {
            :help => 'Password to authenticate against the SCM source repository',
            :category => '1.Global',
            :order => 4
        }

attribute 'connector_config',
          :description => 'Connector Configuration',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Configuration values to add to the connector configuration',
              :category => '1.Global',
              :order => 5
          }
