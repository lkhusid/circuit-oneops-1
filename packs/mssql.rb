include_pack 'genericdb'

name 'mssql'
description 'MS SQL Server'
type 'Platform'
category 'Database Relational SQL'
ignore false

platform :attributes => {'autoreplace' => 'false', 'autocomply' => 'true'}

environment 'single', {}

variable 'temp_drive',
  :description => 'Temp Drive',
  :value       => 'T'

variable 'data_drive',
  :description => 'Data Drive',
  :value       => 'F'

variable 'tcp_port',
  :description => 'TCP Port',
  :value       => '1433'

resource 'secgroup',
         :cookbook => 'oneops.1.secgroup',
         :design => true,
         :attributes => {
             'inbound' => '[ "22 22 tcp 0.0.0.0/0", "$OO_LOCAL{tcp_port} $OO_LOCAL{tcp_port} tcp 0.0.0.0/0", "3389 3389 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => '1..1',
             :services => 'compute'
         }


resource 'mssql',
  :cookbook => 'oneops.1.mssql',
  :design   => true,
  :requires => {
    :constraint => '1..1',
    :services   => 'mirror'
  },
  :attributes   => {
    'version' => 'mssql_2014_enterprise',
    'tcp_port' => '$OO_LOCAL{tcp_port}',
    'tempdb_data' => '$OO_LOCAL{temp_drive}:\\MSSQL',
    'tempdb_log' => '$OO_LOCAL{temp_drive}:\\MSSQL',
    'userdb_data' => '$OO_LOCAL{data_drive}:\\MSSQL\\UserData',
    'userdb_log' => '$OO_LOCAL{data_drive}:\\MSSQL\\UserLog'
  },
  :monitors => {
  'mssql' =>  { :description => 'MSSQL Service check',
     :chart => {'min'=>0},
     :cmd => 'sql_servicemonitor.ps1',
     :cmd_line => 'powershell.exe -file /opt/nagios/libexec/sql_servicemonitor.ps1',
     :metrics =>  {
       'mssqlup'  => metric( :unit => 'mssqlup', :description => 'MSSQL Status'),
       'agentup'  => metric( :unit => 'agentup', :description => 'SQLAGENT status')
     },
     :thresholds => {
        'MssqlProcessDown' => threshold('1m', 'avg', 'mssqlup', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy'),
        'AgentProcessDown' => threshold('1m', 'avg', 'agentup', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
     },
   },
    'databasecheck' =>  { :description => 'MSSQL DB status check',
       :chart => {'min'=>0},
       :cmd => 'sql_dbcount.ps1',
       :cmd_line => 'powershell.exe -file /opt/nagios/libexec/sql_dbcount.ps1',
       :metrics =>  {
         'totaldbs'  => metric(:unit => 'totaldbs', :description => 'Total Number of databases'),
         'offlinedbs'  => metric(:unit => 'offlinedbs', :description => 'Total Number of offline databases'),
       },
       :thresholds  => {
        'offlinedbs' => threshold('1m', 'avg', 'offlinedbs', trigger('>=', 1, 1, 1), reset('<', 1, 1, 1)),
       }
     },
      'latencies' =>  { :description => 'Disk latencies',
         :chart => {'min'=>0},
         :cmd => 'sql_disklatency.ps1',
         :cmd_line => 'powershell.exe -file /opt/nagios/libexec/sql_disklatency.ps1',
         :metrics =>  {
           'logical'  => metric(:unit => 'logical', :description => 'Logical disk latency'),
           'physical'  => metric(:unit => 'physical', :description => 'Physical disk latency'),
         },
         :thresholds  => {
          'logical' => threshold('1m', 'avg', 'logical', trigger('>', 0.015, 1, 1), reset('<', 0.015, 1, 1)),
          'physical' => threshold('1m', 'avg', 'physical', trigger('>', 0.015, 1, 1), reset('<', 0.015, 1, 1))
         }
       }
  }

resource 'compute',
  :cookbook => 'oneops.1.compute',
  :attributes => { 'size'    => 'M-WIN' }

resource 'storage',
  :cookbook => 'oneops.1.storage',
  :requires => { 'constraint' => '1..*', 'services' => 'storage' }

resource 'volume',
  :cookbook => 'oneops.1.volume',
  :requires => {'constraint' => '1..*', 'services' => 'compute,storage'},
  :attributes => { 'mount_point'    => '$OO_LOCAL{data_drive}' }

resource 'vol-temp',
  :cookbook => 'oneops.1.volume',
  :requires => { 'constraint' => '1..1', 'services' => 'compute' },
  :attributes => { 'mount_point'    => '$OO_LOCAL{temp_drive}' }

resource 'os',
  :cookbook => 'oneops.1.os',
  :design => true,
  :requires => {
    :constraint => '1..1',
    :services   => 'compute,*mirror,*ntp,*windows-domain'
    },
    :attributes => {
    :ostype => 'windows_2012_r2'
  }

resource 'dotnetframework',
  :cookbook     => 'oneops.1.dotnetframework',
  :design       => true,
  :requires     => {
    :constraint => '1..1',
    :help       => 'Installs .net frameworks',
    :services   => 'compute,*mirror'
  },
  :attributes   => {
    :chocolatey_package_source   => 'https://chocolatey.org/api/v2/',
    :dotnet_version_package_name => '{ ".Net 4.6":"dotnet4.6", ".Net 3.5":"dotnet3.5" }'
  }

resource 'database',
  :cookbook      => "oneops.1.database",
  :design        => true,
  :requires      => {
    :constraint  => '0..*',
    :help        => 'Installs user database'
  }

resource 'custom-config',
  :cookbook      => "oneops.1.artifact",
  :design        => true,
  :requires      => {
    :constraint  => '0..*',
    :help        => 'Installs custom configuration scripts'
  },
  :attributes       => {
     :install_dir   => '$OO_LOCAL{temp_drive}:/mssql-config',
     :as_user       => 'oneops',
     :as_group      => 'Administrators'
}

[ 
  { :from => 'storage', :to => 'os' },
  { :from => 'vol-temp', :to => 'os' },
  { :from => 'dotnetframework', :to => 'vol-temp' },
  { :from => 'volume', :to => 'storage' },
  { :from => 'mssql', :to => 'volume' } ,
  { :from => 'mssql', :to => 'dotnetframework' } ,
  { :from => 'database', :to => 'mssql' } ,
  { :from => 'custom-config', :to => 'mssql' }
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { 'flex' => false, 'min' => 1, 'max' => 1 }
end

[ 'mssql', 'dotnetframework', 'os', 'volume', 'vol-temp', 'custom-config', 'database' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
