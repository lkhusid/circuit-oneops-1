name             'Mssql'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'Installs/configures Microsoft SQL Server'
version          '0.1.0'

depends 'windows-utils'

grouping 'default',
  :access   => 'global',
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'version',
  :description => 'MS SQL Server version and edition',
  :default     => 'mssql_2014_enterprise',
  :format      => {
    :help      => 'Select version and edition of MS SQL Server to be installed',
    :category  => '1.Global',
    :order     => 1,
    :form => { 'field' => 'select', 'options_for_select' => [ ['2014 Enterprise', 'mssql_2014_enterprise'], ['2016 Enterprise', 'mssql_2016_enterprise'] ] }
    }

attribute 'feature_list',
  :description => 'Feature List',
  :required => 'required',
  :default => 'SQLENGINE,REPLICATION,SNAC_SDK,SSMS',
  :format => {
    :help => 'Comma-separated list of features to install',
    :category => '1.Global',
    :order => 2
  }

attribute 'tcp_port',
  :description => 'TCP Port',
  :required => 'required',
  :default => '1433',
  :format => {
    :help => 'Specify TCP port the database instance will be listening on. The default is 1433',
    :category => '1.Global',
    :order => 3
  }

attribute 'sysadmins',
  :description => 'Sysadmins',
  :format => {
    :help => 'Members of sysadmins server role, comma-separated',
    :category => '2.Security',
    :order => 1
  }

attribute 'password',
  :description => 'sa Password',
  :encrypted => true,
  :format => {
    :help => 'Specify password for sa account',
    :category => '2.Security',
    :order => 2
  }

attribute 'tempdb_data',
  :description => 'TempDB data directory',
  :format => {
    :help => 'Default directory for tempdb data files',
    :category => '3.Directories',
    :order => 1
  }

attribute 'tempdb_log',
  :description => 'TempDB log directory',
  :format => {
    :help => 'Default directory for tempdb log file',
    :category => '3.Directories',
    :order => 2
  }

attribute 'userdb_data',
  :description => 'User db data directory',
  :format => {
    :help => 'Default directory for user databases',
    :category => '3.Directories',
    :order => 3
  }

attribute 'userdb_log',
  :description => 'User db log directory',
  :format => {
    :help => 'Default directory for user database logs',
    :category => '3.Directories',
    :order => 4
  }

recipe "start", "Start SQL Server"
recipe "stop", "Stop SQL Server"
recipe "restart", "Restart SQL Server"
