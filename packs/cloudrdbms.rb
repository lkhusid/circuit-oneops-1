#
# Pack Name:: cloudrdbms
# Maintainer:: GECCloudDB@email.wal-mart.com
# Copyright 2016, walmartlabs
# Cloud RDBMS TEAM
#


include_pack "genericlb"


name "cloudrdbms"
description "CloudRDBMS"
category "Database Relational SQL"
owner "GECCloudDB@email.wal-mart.com"
type		'Platform'


environment "single", {}
environment "redundant", {}

platform :attributes => {'autoreplace' => 'false'}


resource 'compute',
         :cookbook => 'oneops.1.compute',
         :attributes => {'ostype' => 'default-cloud',
                         'size' => 'M'
         }

# this creates a Linux user
resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'App-User',
             'home_directory' => '/app/',
             'system_account' => true,
             'sudoer' => true
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => '*mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {
              :install_dir => "/usr/lib/jvm",
              :jrejdk => "jdk",
              :binpath => "",
              :version => "8",
              :sysdefault => "true",
              :flavor => "oracle"
          }
          
resource "artifact-app",
  :cookbook => "artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  }

resource "volume-app",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/app/',
                    "size"          => '100%FREE',
                    "device"        => '',
                    "fstype"        => 'ext4',
                    "options"       => 'defaults,noatime'
                 },
  :monitors => {
      'usage' =>  {'description' => 'Usage',
                  'chart' => {'min'=>0,'unit'=> 'Percent used'},
                  'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                  'cmd_line' => '/app/monitors/bin/nagios_master.sh "check_disk_use.sh ${NAGIOS_ARG1}" space_used',
                  'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                 'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                  :thresholds => {
                    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                    'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                  }
                }
    }











# be sure to open all ports required by MariaDB and Galera
resource "secgroup",
   :cookbook => "oneops.1.secgroup",
   :design => true,
   :attributes => {
       "inbound" => '[ "22 22 tcp 0.0.0.0/0", "25 59000 tcp 0.0.0.0/0" ]'
   },
   :requires => {
       :constraint => "1..1",
       :services => "compute"
   }





# our Agent Java program needs this:
resource "lb",
:except => [ 'single' ],
:design => true,
:attributes => {
    "listeners"     => '["tcp 3306 tcp 3307"]',
    "ecv_map"     => '{"3307":"port-check"}'
  }

# we use this to have the hostnames stay the same after a compute REPLACE:
resource "hostname",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :services => "dns",
    :help => "optional hostname dns entry"
  }

# our main cookbook / Component
resource 'cloudrdbms',
:cookbook => 'oneops.1.cloudrdbms',
:design => true,
:requires => {
    :constraint => '1..1',
    :help => 'CloudRDBMS'
},
:attributes => { 'cloudrdbmspackversion' => '0.8.0NEXT', 
                 'clustername' => 'dbcluster', 
                 'artifactversion' => 'LATEST-RELEASE',
                 'managedserviceuser' => 'svc_strati_ms', 
                 'managedservicepass' => '', 
                 'concordaddress' => 'server.ms.concord.devtools.prod.walmart.com:8001' },
:monitors => {
    # do not use spaces (nor underscores) in the monitor names
    # MONITOR 1
    'DBprocess' => {:description => 'DBprocess',
        :source => '',
        :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
        # there is a Linux process with name=mysqld  that we want to monitor.  check_process is a script that exists in all oneops VMs. To test/run it manually we can do: /opt/nagios/libexec/check_process.sh mysqld false mysqld
        :cmd => 'DBprocess!mysqld!false!mysqld',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "check_process.sh \"${NAGIOS_ARG1}\" \"${NAGIOS_ARG2}\" \"${NAGIOS_ARG3}\"" DBprocess ',
        :metrics => {
            'up' => metric(:unit => '%', :description => 'Percent Up')
        },
        :thresholds => {
            'Alerts' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
        }},
    # MONITOR 2
    'JavaAgentprocess' => {:description => 'JavaAgentprocess',
        :source => '',
        :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
        # there is a Linux process with name=MySQLAgent  that we want to monitor.  check_process is a script that exists in all oneops VMs. To test/run it manually we can do: /opt/nagios/libexec/check_process.sh MySQLAgent false MySQLAgent
        :cmd => 'JavaAgentprocess!MySQLAgent!false!MySQLAgent',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "check_process.sh \"${NAGIOS_ARG1}\" \"${NAGIOS_ARG2}\" \"${NAGIOS_ARG3}\"" JavaAgentprocess ',
        :metrics => {
            'up' => metric(:unit => '%', :description => 'Percent Up')
        },
        :thresholds => {
            'Alerts' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
        }},
    # MONITOR 3
    'DBalive' => {:description => 'DBalive',
        :source => '',
        :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
        # this script monitor_check_DB.sh  is written by our team: Cloud RDBMS team
        :cmd => 'monitor_check_DB',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "monitor_check_DB.sh" DBalive ',
        :metrics => {
            'DB' => metric(:unit => '%', :description => 'DB Alive')
        },
        :thresholds => {
            'Alerts' => threshold('1m', 'avg', 'DB', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
        }},
    # MONITOR 4
    'JavaAgentLog' => {:description => 'JavaAgentLog',
        :source => '',
        :enable => 'true',
        :chart => {'min' => 0, 'unit' => ''},
        # we are using tag = javaagent.  Tag can be anything. This script (check_logfiles) will incrementally read the log file /app/db/current/bin/cloudrdbms.log  looking for 'warningpattern' and/or 'criticalpattern'
        :cmd => 'JavaAgentLog!javaagent!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "check_logfiles   --noprotocol  --rotation=\"log*\"  --tag=${NAGIOS_ARG1} --logfile=${NAGIOS_ARG2} --warningpattern=\"${NAGIOS_ARG3}\" --criticalpattern=\"${NAGIOS_ARG4}\"" JavaAgentLog ',
        :cmd_options => {
            'logfile' => '/app/db/current/bin/cloudrdbms.log',
            'warningpattern' => 'Exception',
            'criticalpattern' => 'Exception'
        },
        :metrics => {
            'javaagent_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
            'javaagent_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
            'javaagent_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
            'javaagent_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
        },
        :thresholds => {
            'CriticalExceptions' => threshold('1m', 'avg', 'javaagent_criticals', trigger('>', 0, 1, 1), reset('<=', 0, 1, 1))
        }},
    # MONITOR 5
    'ClusterLogErrorCount' => {:description => 'ClusterLogErrorCount',
        :source => '',
        :enable => 'true',
        :chart => {'min' => 0, 'unit' => ''},
        # we are using tag = clusterlog.  Tag can be anything. This script (check_logfiles) will incrementally read the log file /var/lib/mysql/mysqlcloudrdbms.log  looking for 'warningpattern' and/or 'criticalpattern'
        :cmd => 'ClusterLogErrorCount!clusterlog!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "check_logfiles   --noprotocol  --rotation=\"log*\"  --tag=${NAGIOS_ARG1} --logfile=${NAGIOS_ARG2} --warningpattern=\"${NAGIOS_ARG3}\" --criticalpattern=\"${NAGIOS_ARG4}\"" ClusterLogErrorCount ',
        :cmd_options => {
            'logfile' => '/var/lib/mysql/mysqlcloudrdbms.log',
            'warningpattern' => 'Exception',
            'criticalpattern' => 'ERROR'
        },
        :metrics => {
            'clusterlog_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
            'clusterlog_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
            'clusterlog_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
            'clusterlog_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
        },
        :thresholds => {
            'CriticalExceptions' => threshold('1m', 'avg', 'clusterlog_criticals', trigger('>', 0, 1, 1), reset('<=', 0, 1, 1))
        }},
    # MONITOR 6
    'DBmetrics' => {:description => 'DBmetrics',
        :source => '',
        :chart => {'min' => '0', 'max' => '100000', 'unit' => ''},
        # this script monitor_metrics_DB.sh  is written by our team: Cloud RDBMS team
        # notice that this monitor does not have any 'thresholds'.   Thresholds would not really make sense here, as these are performance metrics, so a value of 0 is as valid as a value of "really big number"
        :cmd => 'monitor_metrics_DB',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "monitor_metrics_DB.sh" DBmetrics ',
        :metrics => {
            'selectspersecond' => metric(:unit => 'PERF', :description => 'selects per second', :dstype => 'GAUGE'),
            'updatespersecond' => metric(:unit => 'PERF', :description => 'updates per second', :dstype => 'GAUGE'),
            'insertspersecond' => metric(:unit => 'PERF', :description => 'inserts per second', :dstype => 'GAUGE'),
            'deletespersecond' => metric(:unit => 'PERF', :description => 'deletes per second', :dstype => 'GAUGE'),
            'commitspersecond' => metric(:unit => 'PERF', :description => 'commits per second', :dstype => 'GAUGE')
        }},
    # MONITOR 7
    'ClusterLog2ErrorCount' => {:description => 'ClusterLog2ErrorCount',
        :source => '',
        :enable => 'true',
        :chart => {'min' => 0, 'unit' => ''},
        # we are using tag = clusterlog2.  Tag can be anything. This script (check_logfiles) will incrementally read the log file /var/lib/mysql/innobackup.backup.log  looking for 'warningpattern' and/or 'criticalpattern'
        :cmd => 'ClusterLog2ErrorCount!clusterlog2!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "check_logfiles   --noprotocol  --rotation=\"log*\"  --tag=${NAGIOS_ARG1} --logfile=${NAGIOS_ARG2} --warningpattern=\"${NAGIOS_ARG3}\" --criticalpattern=\"${NAGIOS_ARG4}\"" ClusterLog2ErrorCount ',
        :cmd_options => {
            'logfile' => '/var/lib/mysql/innobackup.backup.log',
            'warningpattern' => 'Exception',
            'criticalpattern' => 'ERROR'
        },
        :metrics => {
            'clusterlog2_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
            'clusterlog2_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
            'clusterlog2_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
            'clusterlog2_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
        },
        :thresholds => {
            'CriticalExceptions' => threshold('1m', 'avg', 'clusterlog2_criticals', trigger('>', 0, 1, 1), reset('<=', 0, 1, 1))
        }},
    # MONITOR 8
    'ClusterMembership' => {:description => 'ClusterMembership',
        :source => '',
        :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
        # this script pcHealthCheck.sh  is written by our team: Cloud RDBMS team
        :cmd => 'pcHealthCheck',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "pcHealthCheck.sh" ClusterMembership ',
        :metrics => {
            'primaryComponent' => metric(:unit => '%', :description => 'Primary Component Exists')
        },
        :thresholds => {
            'Alerts' => threshold('1m', 'avg', 'primaryComponent', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
        }},
    # MONITOR 9
    'DRReplicationLink' => {:description => 'DRReplicationLink',
        :source => '',
        :enable => 'true',
        :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
        # this script monitor_check_drrepllink.sh  is written by our team: Cloud RDBMS team
        :cmd => 'monitor_check_drrepllink',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "monitor_check_drrepllink.sh" DRReplicationLink ',
        :metrics => {
            'drrepllink' => metric(:unit => '%', :description => 'DR Replication Link')
        },
        :thresholds => {
             'Alerts' => threshold('1m', 'avg', 'drrepllink', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
        }},
    # MONITOR 10
    'DBbackup' => {:description => 'DBbackup',
        :source => '',
        :enable => 'false',
        :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
        # this script monitor_backup.sh  is written by our team: Cloud RDBMS team
        :cmd => 'monitor_backup',
        :cmd_line => '/app/monitors/bin/nagios_master.sh "monitor_backup.sh" DBbackup ',
        :metrics => {
            'backup' => metric(:unit => '%', :description => 'DB Backup')
        },
        :thresholds => {
            'Alerts' => threshold('1m', 'avg', 'backup', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
        }},
  # MONITOR 11
  'ActiveThreads' => {:description => 'ActiveThreads',
      :source => '',
      :enable => 'true',
      :cmd_options => {
        'warn_attribute' => '400',
        'alert_attribute' => '600'
      },
      :chart => {'min' => '0', 'unit' => ''},
      # this script  is written by percona and installed by opensysdba team
      :cmd => 'check_mysql_active_threads!#{cmd_options[:warn_attribute]}!#{cmd_options[:alert_attribute]}',
      :cmd_line => '/app/monitors/bin/nagios_master.sh "pmp-check-mysql-status -H $(uname -n) -x Threads_running -w ${NAGIOS_ARG1} -c ${NAGIOS_ARG2}" ActiveThreads ',
      :metrics => {
          'Threads_running' => metric(:unit => '', :description => 'Threads_running', :dstype => 'GAUGE')
      }},
  # MONITOR 12
  'ActiveConnections' => {:description => 'ActiveConnections',
      :source => '',
      :enable => 'true',
      :cmd_options => {
        'warn_attribute' => '400',
        'alert_attribute' => '600'
      },
      :chart => {'min' => '0', 'unit' => ''},
      # this script  is written by percona and installed by opensysdba team
      :cmd => 'check_mysql_connections!#{cmd_options[:warn_attribute]}!#{cmd_options[:alert_attribute]}',
      :cmd_line => '/app/monitors/bin/nagios_master.sh "pmp-check-mysql-status -H $(uname -n) -x Threads_connected -w ${NAGIOS_ARG1} -c ${NAGIOS_ARG2}" ActiveConnections ',
      :metrics => {
          'Threads_connected' => metric(:unit => '', :description => 'Threads_connected', :dstype => 'GAUGE')
      }}
}










# CRON job: for us to be sure that CRON itself is running
resource "cloudCRON",
:cookbook => "oneops.1.job",
:design => true,
:requires => {
    :constraint => "1..1",
    :help => "Run schedule cron job"
},
:attributes => {
    :user => "app",
    'description' => 'CRON to run Cloud RDBMS programs',
    :minute => "*",
    :cmd => "echo FROMCRON-`date` >/app/fromcron.log"
}


# future CRON jobs should not be created in the pack here, see add.rb and cron.jobs.erb









resource "storage",
  :cookbook => "oneops.1.storage",
  :design => true,
  :attributes => {
    "size"        => '25G',
    "slice_count" => '1'
  },
  :requires => { "constraint" => "0..*", "services" => "storage" },
  :payloads => {
    'volumes' => {
     'description' => 'volumes',
     'definition' => '{
       "returnObject": false,
       "returnRelation": false,
       "relationName": "base.RealizedAs",
       "direction": "to",
       "targetClassName": "manifest.oneops.1.Storage",
       "relations": [
         { "returnObject": true,
           "returnRelation": false,
           "relationName": "manifest.DependsOn",
           "direction": "to",
           "targetClassName": "manifest.oneops.1.Volume"
         }
       ]
     }'
   }
  }














# the volume component is for Cinder (or the equivalent in Azure or other cloud providers) - persistent block storage
resource "volume-cinder",
:cookbook => "oneops.1.volume",
:design => true,
:requires => {"constraint" => "0..1", "services" => "compute,storage"},
:attributes => {:mount_point => '/data',
    :size => '100%FREE',
    :device => '',
    :fstype => 'ext4',
    :options => 'defaults,noatime,nodiratime'
},
:monitors => {
    'usage' => {'description' => 'Usage',
        'chart' => {'min' => 0, 'unit' => 'Percent used'},
        'cmd' => 'space_used!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
        'cmd_line' => '/app/monitors/bin/nagios_master.sh "check_disk_use.sh ${NAGIOS_ARG1}" space_used',
        'metrics' => {'space_used' => metric(:unit => '%', :description => 'Disk Space Percent Used'),
            'inode_used' => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
        :thresholds => {
            'LowDiskSpace' => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
            'LowDiskInode' => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
        }
    }
}





















# for swift / objectstore
resource "objectstore",
:cookbook => "oneops.1.objectstore",
:design => true,
:requires => {
    :constraint => "0..1",
    :services => "filestore"
}

























# notice below, our FIRST CRON entry depends on compute/cloudrdbms; and our SECOND CRON entry (if it exists here) should depend on the FIRST.  All CRON resources need to be in the 'managed_via' block





# this will give the user a 3-VM cluster by default
# depends_on
[ 'lb' ].each do |from|
    relation "#{from}::depends_on::compute",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'both', "flex" => true, "current" => 3, "min" => 3, "max" => 21}
end




# depends_on
[
{:from => 'cloudrdbms', :to => 'compute'},
{:from => 'cloudrdbms', :to => 'user-app'},
{:from => 'user-app', :to => 'volume-app'},
{:from => 'user-app', :to => 'compute'},
{:from => 'cloudrdbms', :to => 'java'},
{:from => 'java', :to => 'os'},
{:from => 'cloudrdbms', :to => 'volume-app'},
{:from => 'artifact-app', :to => 'volume-app'},
{:from => 'volume-app', :to => 'os'},
{:from => 'cloudCRON', :to => 'compute'},
{:from => 'cloudCRON', :to => 'cloudrdbms'},
{:from => 'storage', :to => 'compute'},
{:from => 'volume-cinder', :to => 'storage'},
{:from => 'cloudrdbms', :to => 'volume-cinder'},
{:from => 'objectstore', :to => 'compute'},
{:from => 'telegraf', :to => 'compute'},
{:from => 'telegraf', :to => 'cloudrdbms'}
].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource => link[:to],
    :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# if a compute is replace, touch-update hostname
[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { 'propagate_to' => 'from' }
end

# managed_via
[ 'cloudrdbms', 'user-app', 'java', 'volume-app', 'artifact-app', 'cloudCRON', 'volume-cinder', 'objectstore'].each do |from|
    relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
















# procedures at the 'platform' level (1 level above 'component') on the deployed environment: those will run on all VMs
# targetClassName: first letter of Cloudrdbms needs to be UPPERCASE

[
 {:name => 'stop-all-in-parallel', :strategy => 'parallel', :description => 'Stop all nodes in parallel', :action => 'stop'}
].each do |link|
    procedure "#{link[:name]}",
       :description => "#{link[:description]}",
       #:arguments => '{"arg1":"","arg2":""}',
       :definition => '{
         "flow": [
                  {
                   "execStrategy": "'+link[:strategy]+'",
                   "relationName": "manifest.Requires",
                   "direction": "from",
                   "targetClassName": "manifest.oneops.Cloudrdbms",
                   "flow": [
                            {
                             "relationName": "base.RealizedAs",
                             "execStrategy": "'+link[:strategy]+'",
                             "direction": "from",
                             "targetClassName": "bom.oneops.Cloudrdbms",
                             "actions": [
                                         {
                                          "actionName": "'+link[:action]+'",
                                          "stepNumber": 1,
                                          "isCritical": true
                                         }
                                        ]
                            }
                           ]
                  }
                 ]
}'

end



