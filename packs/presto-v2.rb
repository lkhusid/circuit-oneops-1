include_pack "base"

name "presto-v2"
description "Presto (V2 Build)"
type "Platform"
category "Presto"

# Versioning attributes
presto_version = "2"
presto_cookbook = "oneops.1.presto-v#{presto_version}"
presto_coordinator_cookbook = "oneops.1.presto-coordinator-v#{presto_version}"
presto_cluster_cookbook = "oneops.1.presto-cluster-v#{presto_version}"
presto_cassandra_cookbook = "oneops.1.presto-cassandra-v#{presto_version}"
presto_mysql_cookbook = "oneops.1.presto-mysql-v#{presto_version}"
presto_swift_cookbook = "oneops.1.presto-swift-v#{presto_version}"
# When changing version, need to change the class name in payload definitions.

platform :attributes => {'autoreplace' => 'false'}

# ==== START: Cluster-wide resources ====
resource 'secgroup',
         :cookbook   => 'oneops.1.secgroup',
         :design     => true,
         :attributes => {
           # Port configuration:
           #
           #  null:  Ping
           #    22:  SSH
           #  8443:  Presto HTTPS communication
           # 60000:  For mosh
           #
           "inbound" => '[

               "null null 4 0.0.0.0/0",
               "22 22 tcp 0.0.0.0/0",
               "8443 8443 tcp 0.0.0.0/0",
               "60000 60100 udp 0.0.0.0/0"
           ]'
         },
         :requires   => {
           :constraint => '1..1',
           :services   => 'compute'
         }

resource 'presto-cluster',
         :except   => ['single'],
         :cookbook => presto_cluster_cookbook,
         :design   => false,
         :requires => {:constraint => '1..1', :services => 'dns'},
         :monitors => {
#             'Coordinator' => {
#                 :description => 'Coordinator Status',
#                 :source => '',
#                 :chart => {'min' => 0, 'unit' => ''},
#                 :cmd => 'check_http_status!#{cmd_options[:url]}!#{cmd_options[:wait]}!#{cmd_options[:expect]}!#{cmd_options[:regex]}',
#                 :cmd_line => '/opt/nagios/libexec/check_lb_http_status.sh "$ARG1$" $ARG2$ "$ARG3$" $ARG4$',
#                 :cmd_options => {
#                     # Host will be grabbed from the LB FQDN
#                     #'host' => 'localhost',
#                     # Port is specified in the Presto component config
#                     #'port' => '8080',
#                     'url' => '/v1/info/coordinator',
#                     'wait' => '15',
#                     'expect' => '200 OK',
#                     'regex' => ''
#                 },
#                 :metrics => {
#                     'time' => metric(:unit => 's', :description => 'Response Time', :dstype => 'GAUGE'),
#                     'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE'),
#                     'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false)
#                 },
#                 :thresholds => {
#                     'CoordDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
#                 }
#             }
         },
         :payloads => {
           # clusterCoord - The compute instances for all computes in
           #                the deployment
           #                Path: Cluster definition (starting point)
           #                      -> Platform definition
           #                      -> compute-coord definition
           #                      -> realized as compute (compute-coord instance)
           'clusterCoord' => {
             'description' => 'Presto Coordinators',
             'definition' => '{
               "returnObject": false,
               "returnRelation": false,
               "relationName": "base.RealizedAs",
               "direction": "to",
               "targetClassName": "manifest.oneops.1.Presto-cluster-v2",
               "relations": [
                 { "returnObject": false,
                   "returnRelation": false,
                   "relationName": "manifest.DependsOn",
                   "direction": "from",
                   "targetClassName": "manifest.oneops.1.Presto-v2",
                   "relations": [
                     { "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.DependsOn",
                       "direction": "from",
                       "targetClassName": "manifest.oneops.1.Presto-v2",
                       "relations": [
                         { "returnObject": false,
                           "returnRelation": false,
                           "relationName": "manifest.DependsOn",
                           "direction": "from",
                           "targetClassName": "manifest.oneops.1.Compute",
                           "relations": [
                             { "returnObject": true,
                               "returnRelation": false,
                               "relationName": "base.RealizedAs",
                               "direction": "from",
                               "targetClassName": "bom.oneops.1.Compute"
                             }
                           ]
                         }
                       ]
                     }
                   ]
                 }
               ]
             }'
           }
         }

# ==== END: Cluster-wide resources ====

# === START: Presto coordinator resources ====
resource "compute-coord",
         :cookbook => "oneops.1.compute",
         :design => true,
         :requires => { "constraint" => "1..1", "services" => "compute,dns,*mirror" },
         :attributes => { "size"    => "S"
                        },
         :monitors => {
             'ssh' =>  { :description => 'SSH Port',
                         :chart => {'min'=>0},
                         :cmd => 'check_port',
                         :cmd_line => '/opt/nagios/libexec/check_port.sh',
                         :heartbeat => true,
                         :duration => 5,
                         :metrics =>  {
                           'up'  => metric( :unit => '%', :description => 'Up %')
                         },
                         :thresholds => {
                         },
                       }
         },
         :payloads => {
           'os' => {
             'description' => 'os',
             'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.oneops.1.Compute",
                "relations": [
                  { "returnObject": true,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "to",
                    "targetClassName": "manifest.oneops.1.Os"
                  }
                ]
             }'
           }
         }

resource "os-coord",
         :cookbook => "oneops.1.os",
         :design => true,
         :requires => { "constraint" => "1..1", "services" => "compute,dns,*mirror,*ntp,*windows-domain" },
         :attributes => { "ostype"  => "centos-7.0",
                          "dhclient"  => 'true'
                        },
         :monitors => {
             'cpu' =>  { :description => 'CPU',
                         :source => '',
                         :chart => {'min'=>0,'max'=>100,'unit'=>'Percent'},
                         :cmd => 'check_local_cpu!10!5',
                         :cmd_line => '/opt/nagios/libexec/check_cpu.sh $ARG1$ $ARG2$',
                         :metrics =>  {
                           'CpuUser'   => metric( :unit => '%', :description => 'User %'),
                           'CpuNice'   => metric( :unit => '%', :description => 'Nice %'),
                           'CpuSystem' => metric( :unit => '%', :description => 'System %'),
                           'CpuSteal'  => metric( :unit => '%', :description => 'Steal %'),
                           'CpuIowait' => metric( :unit => '%', :description => 'IO Wait %'),
                           'CpuIdle'   => metric( :unit => '%', :description => 'Idle %', :display => false)
                         },
                         :thresholds => {
                            'HighCpuPeak' => threshold('5m','avg','CpuIdle',trigger('<=',10,5,1),reset('>',20,5,1)),
                            'HighCpuUtil' => threshold('1h','avg','CpuIdle',trigger('<=',20,60,1),reset('>',30,60,1))
                         }
                       },
             'load' => { :description => 'Load',
                         :chart => {'min'=>0},
                         :cmd => 'check_local_load!5.0,4.0,3.0!10.0,6.0,4.0',
                         :cmd_line => '/opt/nagios/libexec/check_load -w $ARG1$ -c $ARG2$',
                         :duration => 5,
                         :metrics =>  {
                           'load1'  => metric( :unit => '', :description => 'Load 1min Average'),
                           'load5'  => metric( :unit => '', :description => 'Load 5min Average'),
                           'load15' => metric( :unit => '', :description => 'Load 15min Average'),
                         },
                         :thresholds => {
                         },
                       },
             'disk' => { 'description' => 'Disk',
                         'chart' => {'min'=>0,'unit'=> '%'},
                         'cmd' => 'check_disk_use!/',
                         'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                         'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                        'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                         :thresholds => {
                           'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                           'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                         },
                       },
             'mem' =>  { 'description' => 'Memory',
                         'chart' => {'min'=>0,'unit'=>'KB'},
                         'cmd' => 'check_local_mem!90!95',
                         'cmd_line' => '/opt/nagios/libexec/check_mem.pl -Cu -w $ARG1$ -c $ARG2$',
                         'metrics' =>  {
                           'total'  => metric( :unit => 'KB', :description => 'Total Memory'),
                           'used'   => metric( :unit => 'KB', :description => 'Used Memory'),
                           'free'   => metric( :unit => 'KB', :description => 'Free Memory'),
                           'caches' => metric( :unit => 'KB', :description => 'Cache Memory')
                         },
                         :thresholds => {
                         },
                       },
             'network' => { :description => 'Network',
                            :source => '',
                            :chart => {'min' => 0, 'unit' => ''},
                            :cmd => 'check_network_bandwidth',
                            :cmd_line => '/opt/nagios/libexec/check_network_bandwidth.sh',
                            :metrics => {
                              'rx_bytes' => metric(:unit => 'bytes', :description => 'RX Bytes', :dstype => 'DERIVE'),
                              'tx_bytes' => metric(:unit => 'bytes', :description => 'TX Bytes', :dstype => 'DERIVE')
                            }
                          }
         },
         :payloads => {
           'linksto' => {
           'description' => 'LinksTo',
           'definition' => '{
             "returnObject": false,
             "returnRelation": false,
             "relationName": "base.RealizedAs",
             "direction": "to",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.Requires",
                 "direction": "to",
                 "targetClassName": "manifest.Platform",
                 "relations": [
                   { "returnObject": false,
                     "returnRelation": false,
                     "relationName": "manifest.LinksTo",
                     "direction": "from",
                     "targetClassName": "manifest.Platform",
                     "relations": [
                       { "returnObject": true,
                         "returnRelation": false,
                         "relationName": "manifest.Entrypoint",
                         "direction": "from"
                       }
                     ]
                   }
                 ]
               }
             ]
           }'
         }
       }

resource 'user-coord',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => { "constraint" => "0..*" }

resource "library-coord",
         :cookbook => "oneops.1.library",
         :design => true,
         :requires => { "constraint" => "0..*" }

resource "file-coord",
         :cookbook => "oneops.1.file",
         :design => true,
         :requires => {
            :constraint => "0..*",
            :help => <<-eos
The optional <strong>file-coord</strong> component can be used to create customized files.
For example, you can create configuration file needed for your applications or other components.
A file can also be a shell script which can be executed with the optional execute command attribute.
eos
         }

resource "download-coord",
         :cookbook => "oneops.1.download",
         :design => true,
         :requires => { "constraint" => "0..*" }

resource 'java-coord',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => 'mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {
           'flavor' => 'oracle',
           'jrejdk' => 'server-jre'
         }

resource "hostname-coord",
         :cookbook => "oneops.1.fqdn",
         :design => true,
         :requires => {
           :constraint => "1..1",
           :services => "dns",
           :help => "hostname dns entry"
         }

resource 'artifact',
         :cookbook => 'oneops.1.artifact',
         :design => true,
         :requires => { 'constraint' => '0..*' },
         :attributes => {

         },
         :monitors => {
             'URL' => { :description => 'URL',
                        :source => '',
                        :chart => { 'min' => 0, 'unit' => '' },
                        :cmd => 'check_http_status!#{cmd_options[:host]}!#{cmd_options[:port]}!#{cmd_options[:url]}!#{cmd_options[:wait]}!#{cmd_options[:expect]}!#{cmd_options[:regex]}',
                        :cmd_line => '/opt/nagios/libexec/check_http_status.sh $ARG1$ $ARG2$ "$ARG3$" $ARG4$ "$ARG5$" "$ARG6$"',
                        :cmd_options => {
                            'host' => 'localhost',
                            'port' => '8080',
                            'url' => '/',
                            'wait' => '15',
                            'expect' => '200 OK',
                            'regex' => ''
                        },
                        :metrics => {
                            'time' => metric(:unit => 's', :description => 'Response Time', :dstype => 'GAUGE'),
                            'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE'),
                            'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false)
                        },
                        :thresholds => {

                        } }
         }

resource "hadoop-yarn-config",
        :cookbook => "oneops.1.hadoop-yarn-config-v1",
        :design => true,
        :requires => {
            :constraint => "1..1",
            :services => "dns",
            :help => "client"
        }

resource "client-yarn-coord",
        :cookbook => "oneops.1.hadoop-yarn-v1",
        :design => true,
        :requires => {
            :constraint => "1..1",
            :services => "dns",
            :help => "resource manager"
        },
        :monitors => {
            'CheckMetastore' => { :description => 'Hive Metastore Process',
                                  :source      => '',
                                  :chart       => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                                  :cmd         => 'check_process!hive-metastore!false!org.apache.hadoop.hive.metastore.HiveMetaStore',
                                  :cmd_line    => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                                  :metrics     => {
                                      'up' => metric(:unit => '%', :description => 'Percent Up'),
                                  },
                                  :thresholds  => {
                                      'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                                  } }
        },
        :payloads => {
            'yarnconfigci' => {
                'description' => 'hadoop yarn configurations',
                'definition' => '{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "base.RealizedAs",
                    "direction": "to",
                    "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                    "relations": [{
                        "returnObject": true,
                        "returnRelation": false,
                        "relationName": "manifest.DependsOn",
                        "direction": "from",
                        "targetClassName": "manifest.oneops.1.Hadoop-yarn-config-v1"
                    }]
                }'
            },
            'allFqdn' => {
                'description' => 'All Fqdns',
                'definition' => '{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "base.RealizedAs",
                    "direction": "to",
                    "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                    "relations": [{
                        "returnObject": false,
                        "returnRelation": false,
                        "relationName": "manifest.Requires",
                        "direction": "to",
                        "targetClassName": "manifest.Platform",
                        "relations": [{
                            "returnObject": false,
                            "returnRelation": false,
                            "relationName": "manifest.Requires",
                            "direction": "from",
                            "targetClassName": "manifest.oneops.1.Fqdn",
                            "relations": [{
                                "returnObject": true,
                                "returnRelation": false,
                                "relationName": "base.RealizedAs",
                                "direction": "from",
                                "targetClassName": "bom.oneops.1.Fqdn"
                            }]
                        }]
                    }]
                }'
            }
        }

resource "certificate-coord",
         :cookbook => "oneops.1.certificate",
         :design => true,
         :requires => { "constraint" => "0..*", 'services' => '*certificate' },
         :attributes => {},
         :monitors => {
             'ExpiryMetrics' =>  { :description => 'ExpiryMetrics',
                 :source => '',
                 :chart => {'min'=>0, 'unit'=>'Per Minute'},
                 :charts => [
                   {'min'=>0, 'unit'=>'Current Count', 'metrics'=>["days_remaining"]}
                 ],
                 :cmd => 'check_cert!:::node.expiry_date_in_seconds:::',
                 :cmd_line => '/opt/nagios/libexec/check_cert $ARG1$',
                 :metrics =>  {
                   'minutes_remaining'   => metric( :unit => 'count', :description => 'Minutes remaining to Expiry', :dstype => 'GAUGE'),
                   'hours_remaining'   => metric( :unit => 'count', :description => 'Hours remaining to Expiry', :dstype => 'GAUGE'),
                   'days_remaining'   => metric( :unit => 'count', :description => 'Days remaining to Expiry', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                   'cert-expiring-soon' => threshold('1m','avg','days_remaining',trigger('<=',30,1,1),reset('>',90,1,1))
                 }
             }
         }

resource "keystore-coord",
         :cookbook => "oneops.1.keystore",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             "keystore_filename" => "/etc/presto/keystore/presto_keystore.jks",
             "keystore_password" => "changeit"
         }

resource 'presto',
         :cookbook => presto_cookbook,
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => 'mirror'
         },
         :attributes => {
         },
         :monitors => {
             'CheckPresto' => { :description => 'Presto Process',
                                :source      => '',
                                :chart       => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                                :cmd         => 'check_process!presto!false!com.facebook.presto.server.PrestoServer',
                                :cmd_line    => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                                :metrics     => {
                                    'up' => metric(:unit => '%', :description => 'Percent Up'),
                                },
                                :thresholds  => {
                                    'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                                } },
             'HttpValue' => { :description => 'HttpValue',
                              :source => '',
                              :chart => { 'min' => 0, 'unit' => '' },
                              :cmd => 'check_http_value!#{cmd_options[:url]}!#{cmd_options[:format]}',
                              :cmd_line => '/opt/nagios/libexec/check_http_value.rb $ARG1$ $ARG2$',
                              :cmd_options => {
                                  'url' => '',
                                  'format' => ''
                              },
                              :metrics => {
                                  'value' => metric(:unit => '', :description => 'value', :dstype => 'DERIVE')

                              } },
             'JvmInfo' => { :description => 'JvmInfo',
                            :source => '',
                            :chart => { 'min' => 0, 'unit' => '' },
                            :cmd => 'check_presto_jvm',
                            :cmd_line => '/opt/nagios/libexec/check_presto.rb JvmInfo',
                            :metrics => {
                                'max' => metric(:unit => 'B', :description => 'Max Allowed', :dstype => 'GAUGE'),
                                'free' => metric(:unit => 'B', :description => 'Free', :dstype => 'GAUGE'),
                                'total' => metric(:unit => 'B', :description => 'Allocated', :dstype => 'GAUGE'),
                                'percentUsed' => metric(:unit => 'Percent', :description => 'Percent Memory Used', :dstype => 'GAUGE')
                            },
                            :thresholds => {
                                'HighMemUse' => threshold('5m', 'avg', 'percentUsed', trigger('>', 98, 15, 1), reset('<', 98, 5, 1))
                            } },
           'ServerLog' => { :description => 'Presto Server Log',
                            :source => '',
                            :chart => {'min' => 0, 'unit' => ''},
                            :cmd => 'check_logfiles!logprestoserver!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                            :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                            :cmd_options => {
                                'logfile' => '/var/log/presto/server.log',
                                'warningpattern' => 'WARN',
                                'criticalpattern' => 'ERROR'
                            },
                            :metrics => {
                                'logprestoserver_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                                'logprestoserver_errors' => metric(:unit => 'errors', :description => 'Errors', :dstype => 'GAUGE'),
                                'logprestoserver_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                                'logprestoserver_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                            },
                            :thresholds => {
                                'CriticalLogException' => threshold('1m', 'avg', 'criticals', trigger('>=', 1, 1, 1), reset('<', 1, 1, 1),'unhealthy'),
                            } }
         }

resource 'presto_coordinator',
       :cookbook => presto_coordinator_cookbook,
       :design => true,
       :requires => { 'constraint' => '1..1', 'services' => 'dns' },
       :payloads => {
         'coord1' => {
           'description' => 'Presto Coordinators',
           'definition' => '{
             "returnObject": false,
             "returnRelation": false,
             "relationName": "base.RealizedAs",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Presto-coordinator-v2",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.DependsOn",
                 "direction": "from",
                 "targetClassName": "manifest.oneops.1.Presto-v2",
                 "relations": [
                   { "returnObject": false,
                     "returnRelation": false,
                     "relationName": "manifest.DependsOn",
                     "direction": "from",
                     "targetClassName": "manifest.oneops.1.Compute",
                     "relations": [
                       { "returnObject": true,
                         "returnRelation": false,
                         "relationName": "base.RealizedAs",
                         "direction": "from",
                         "targetClassName": "bom.oneops.1.Compute"
                       }
                     ]
                   }
                 ]
               }
             ]
           }'
         },
         # primaryCloud - All clouds included in the deployment
         #                Path: Coordinator definition (starting point)
         #                      -> requires (Platform)
         #                      -> consumes cloud (Clouds) [filtered by priority = '1']
         'primaryCloud' => {
           'description' => 'Primary Clouds in Deployment',
           'definition' => '{
             "returnObject": false,
             "returnRelation": false,
             "relationName": "base.RealizedAs",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Presto-coordinator-v2",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.Requires",
                 "direction": "to",
                 "targetClassName": "manifest.Platform",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "base.Consumes",
                     "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                      {"attributeName":"adminstatus", "condition":"eq", "avalue":"active"}],
                     "direction": "from",
                     "targetClassName": "account.Cloud"
                   }
                 ]
               }
             ]
           }'
         }
       }


resource 'presto_mysql',
       :cookbook => presto_mysql_cookbook,
       :design => true,
       :requires => { 'constraint' => '0..*' }

resource 'presto_cassandra',
      :cookbook => presto_cassandra_cookbook,
      :design => true,
      :requires => { 'constraint' => '0..*' }

resource 'presto_swift',
       :cookbook => presto_swift_cookbook,
       :design => true,
       :requires => { 'constraint' => '1..1' }

# === END: Presto coordinator resources ====

# === START: Presto worker resources ====

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => 'mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {
           'flavor' => 'oracle',
           'jrejdk' => 'server-jre'
         }

resource "hostname",
         :cookbook => "oneops.1.fqdn",
         :design => true,
         :requires => {
           :constraint => "1..1",
           :services => "dns",
           :help => "hostname dns entry"
         }

resource "client-yarn",
        :cookbook => "oneops.1.hadoop-yarn-v1",
        :design => true,
        :requires => {
            :constraint => "1..1",
            :services => "dns",
            :help => "resource manager"
        },
        :monitors => {
            'CheckMetastore' => { :description => 'Hive Metastore Process',
                                  :source      => '',
                                  :chart       => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                                  :cmd         => 'check_process!hive-metastore!false!org.apache.hadoop.hive.metastore.HiveMetaStore',
                                  :cmd_line    => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                                  :metrics     => {
                                      'up' => metric(:unit => '%', :description => 'Percent Up'),
                                  },
                                  :thresholds  => {
                                      'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                                  } }
        },
        :payloads => {
            'yarnconfigci' => {
                'description' => 'hadoop yarn configurations',
                'definition' => '{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "base.RealizedAs",
                    "direction": "to",
                    "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                    "relations": [{
                        "returnObject": true,
                        "returnRelation": false,
                        "relationName": "manifest.DependsOn",
                        "direction": "from",
                        "targetClassName": "manifest.oneops.1.Hadoop-yarn-config-v1"
                    }]
                }'
            },
            'allFqdn' => {
                'description' => 'All Fqdns',
                'definition' => '{
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "base.RealizedAs",
                    "direction": "to",
                    "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                    "relations": [{
                        "returnObject": false,
                        "returnRelation": false,
                        "relationName": "manifest.Requires",
                        "direction": "to",
                        "targetClassName": "manifest.Platform",
                        "relations": [{
                            "returnObject": false,
                            "returnRelation": false,
                            "relationName": "manifest.Requires",
                            "direction": "from",
                            "targetClassName": "manifest.oneops.1.Fqdn",
                            "relations": [{
                                "returnObject": true,
                                "returnRelation": false,
                                "relationName": "base.RealizedAs",
                                "direction": "from",
                                "targetClassName": "bom.oneops.1.Fqdn"
                            }]
                        }]
                    }]
                }'
            }
        }

resource 'presto_worker',
         :cookbook => presto_cookbook,
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => 'mirror'
         },
         :attributes => {
         },
         :monitors => {
             'CheckPresto' => { :description => 'Presto Process',
                                :source      => '',
                                :chart       => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                                :cmd         => 'check_process!presto!false!com.facebook.presto.server.PrestoServer',
                                :cmd_line    => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                                :metrics     => {
                                    'up' => metric(:unit => '%', :description => 'Percent Up'),
                                },
                                :thresholds  => {
                                    'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                                } },
             'HttpValue' => { :description => 'HttpValue',
                              :source => '',
                              :chart => { 'min' => 0, 'unit' => '' },
                              :cmd => 'check_http_value!#{cmd_options[:url]}!#{cmd_options[:format]}',
                              :cmd_line => '/opt/nagios/libexec/check_http_value.rb $ARG1$ $ARG2$',
                              :cmd_options => {
                                  'url' => '',
                                  'format' => ''
                              },
                              :metrics => {
                                  'value' => metric(:unit => '', :description => 'value', :dstype => 'DERIVE')

                              } },
             'JvmInfo' => { :description => 'JvmInfo',
                            :source => '',
                            :chart => { 'min' => 0, 'unit' => '' },
                            :cmd => 'check_presto_jvm',
                            :cmd_line => '/opt/nagios/libexec/check_presto.rb JvmInfo',
                            :metrics => {
                                'max' => metric(:unit => 'B', :description => 'Max Allowed', :dstype => 'GAUGE'),
                                'free' => metric(:unit => 'B', :description => 'Free', :dstype => 'GAUGE'),
                                'total' => metric(:unit => 'B', :description => 'Allocated', :dstype => 'GAUGE'),
                                'percentUsed' => metric(:unit => 'Percent', :description => 'Percent Memory Used', :dstype => 'GAUGE')
                            },
                            :thresholds => {
                                'HighMemUse' => threshold('5m', 'avg', 'percentUsed', trigger('>', 98, 15, 1), reset('<', 98, 5, 1))
                            } },
           'ServerLog' => { :description => 'Presto Server Log',
                            :source => '',
                            :chart => {'min' => 0, 'unit' => ''},
                            :cmd => 'check_logfiles!logprestoserver!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                            :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                            :cmd_options => {
                                'logfile' => '/var/log/presto/server.log',
                                'warningpattern' => 'WARN',
                                'criticalpattern' => 'ERROR'
                            },
                            :metrics => {
                                'logprestoserver_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                                'logprestoserver_errors' => metric(:unit => 'errors', :description => 'Errors', :dstype => 'GAUGE'),
                                'logprestoserver_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                                'logprestoserver_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                            },
                            :thresholds => {
                                'CriticalLogException' => threshold('1m', 'avg', 'criticals', trigger('>=', 1, 1, 1), reset('<', 1, 1, 1),'unhealthy'),
                            } }
         }

resource 'presto_coordinator_worker',
       :cookbook => presto_coordinator_cookbook,
       :design => true,
       :requires => { 'constraint' => '1..1', 'services' => 'dns' },
       :payloads => {
         'coord2' => {
           'description' => 'Presto Coordinators',
           'definition' => '{
             "returnObject": false,
             "returnRelation": false,
             "relationName": "base.RealizedAs",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Presto-coordinator-v2",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.DependsOn",
                 "direction": "from",
                 "targetClassName": "manifest.oneops.1.Presto-v2",
                 "relations": [
                   { "returnObject": false,
                     "returnRelation": false,
                     "relationName": "manifest.DependsOn",
                     "direction": "from",
                     "targetClassName": "manifest.oneops.1.Presto-v2",
                     "relations": [
                       { "returnObject": false,
                         "returnRelation": false,
                         "relationName": "manifest.DependsOn",
                         "direction": "from",
                         "targetClassName": "manifest.oneops.1.Compute",
                         "relations": [
                           { "returnObject": true,
                             "returnRelation": false,
                             "relationName": "base.RealizedAs",
                             "direction": "from",
                             "targetClassName": "bom.oneops.1.Compute"
                           }
                         ]
                       }
                     ]
                   }
                 ]
               }
             ]
           }'
         },
         # primaryCloud - All clouds included in the deployment
         #                Path: Coordinator definition (starting point)
         #                      -> requires (Platform)
         #                      -> consumes cloud (Clouds) [filtered by priority = '1']
         'primaryCloud' => {
           'description' => 'Primary Clouds in Deployment',
           'definition' => '{
             "returnObject": false,
             "returnRelation": false,
             "relationName": "base.RealizedAs",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Presto-coordinator-v2",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.Requires",
                 "direction": "to",
                 "targetClassName": "manifest.Platform",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "base.Consumes",
                     "relationAttrs":[{"attributeName":"priority", "condition":"eq", "avalue":"1"},
                                      {"attributeName":"adminstatus", "condition":"eq", "avalue":"active"}],
                     "direction": "from",
                     "targetClassName": "account.Cloud"
                   }
                 ]
               }
             ]
           }'
         },
         'coordConfig' => {
           'description' => 'Presto Coordinator Configuration',
           'definition' => '{
             "returnObject": false,
             "returnRelation": false,
             "relationName": "base.RealizedAs",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Presto-coordinator-v2",
             "relations": [
               { "returnObject": false,
                 "returnRelation": false,
                 "relationName": "manifest.DependsOn",
                 "direction": "from",
                 "targetClassName": "manifest.oneops.1.Presto-v2",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "manifest.DependsOn",
                     "direction": "from",
                     "targetClassName": "manifest.oneops.1.Presto-v2"
                   }
                 ]
               }
             ]
           }'
         }
       }


resource 'presto_mysql_worker',
       :cookbook => presto_mysql_cookbook,
       :design => true,
       :requires => { 'constraint' => '0..*' }

resource 'presto_cassandra_worker',
      :cookbook => presto_cassandra_cookbook,
      :design => true,
      :requires => { 'constraint' => '0..*' }

resource 'presto_swift_worker',
       :cookbook => presto_swift_cookbook,
       :design => true,
       :requires => { 'constraint' => '1..1' }

# === END: Presto worker resources ====

# ==== Relationships - cluster ====
relation "fqdn::depends_on::presto-cluster",
         :except => [ '_default', 'single' ],
         :relation_name => 'DependsOn',
         :from_resource => 'fqdn',
         :to_resource   => 'presto-cluster',
         :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }

[ 'presto-cluster' ].each do |from|
    relation "#{from}::managed_via::compute",
             :except => ['_default', 'single'],
             :relation_name => 'ManagedVia',
             :from_resource => from,
             :to_resource => 'compute',
             :attributes => {}
end

# ==== Relationships - master ====

# depends_on
[{ :from => 'presto',     :to => 'java-coord' },
 { :from => 'keystore-coord', :to => 'presto' },
 { :from => 'certificate-coord', :to => 'os-coord' },
 { :from => 'client-yarn-coord', :to => 'java-coord' },
 { :from => 'presto',     :to => 'compute-coord' },
 { :from => 'presto',     :to => 'user-coord' },
 { :from => 'file-coord',       :to => 'os-coord' },
 { :from => 'library-coord',    :to => 'os-coord' },
 { :from => 'java-coord',       :to => 'os-coord' },
 { :from => 'java-coord',       :to => 'download-coord' },
 { :from => 'hostname-coord',       :to => 'os-coord' },
 { :from => 'hostname-coord',       :to => 'compute-coord' },
 { :from => 'os-coord',       :to => 'compute-coord' },
 { :from => 'user-coord',       :to => 'compute-coord' },
 { :from => 'user-coord',       :to => 'os-coord' },
 { :from => 'download-coord',       :to => 'os-coord' }
   ].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
             :relation_name => 'DependsOn',
             :from_resource => link[:from],
             :to_resource => link[:to],
             :attributes => { 'flex' => false, 'min' => 1, 'max' => 1 }
end

[{ :from => 'presto_coordinator', :to => 'presto' },
 { :from => 'presto_coordinator', :to => 'keystore-coord' },
 { :from => 'presto_coordinator', :to => 'client-yarn-coord' },
 { :from => 'keystore-coord', :to => 'certificate-coord' },
 { :from => 'presto_mysql', :to => 'presto_coordinator' },
 { :from => 'presto_cassandra', :to => 'presto_coordinator' },
 { :from => 'presto_swift', :to => 'presto_coordinator' },
 { :from => 'presto_swift', :to => 'client-yarn-coord' }
   ].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
             :relation_name => 'DependsOn',
             :from_resource => link[:from],
             :to_resource => link[:to],
             :attributes => { :propagate_to => 'from', 'flex' => false, 'min' => 1, 'max' => 1 }
end

[{ :from => 'client-yarn-coord', :to => 'hadoop-yarn-config' }
   ].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
             :relation_name => 'DependsOn',
             :from_resource => link[:from],
             :to_resource => link[:to],
             :attributes => { :propagate_to => 'from', 'flex' => false, "converge" => true, 'min' => 1, 'max' => 1 }
end

relation "compute-coord::depends_on::secgroup",
    :relation_name => 'DependsOn',
    :from_resource => 'compute-coord',
    :to_resource   => 'secgroup',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }

[ 'presto_coordinator' ].each do |from|
  relation "#{from}::depends_on::presto",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'presto',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

[ 'presto' ].each do |from|
  relation "#{from}::depends_on::compute-coord",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute-coord',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
['presto', 'artifact', 'file-coord', 'library-coord',
    'java-coord', 'user-coord', 'os-coord',
    'presto_coordinator', 'presto_mysql', 'presto_cassandra',
    'presto_swift', 'client-yarn-coord', 'keystore-coord', 'certificate-coord' ].each do |from|
    relation "#{from}::managed_via::compute-coord",
             :except => ['_default'],
             :relation_name => 'ManagedVia',
             :from_resource => from,
             :to_resource => 'compute-coord',
             :attributes => {}
end

# Secure the coordinator compute with the ssh keys
[ 'compute-coord'].each do |from|
   relation "#{from}::secured_by::sshkeys",
       :except => [ '_default' ],
       :relation_name => 'SecuredBy',
       :from_resource => from,
       :to_resource   => 'sshkeys',
       :attributes    => { }
end

# ==== Relationships - worker ====
# depends_on
[{ :from => 'presto_worker',     :to => 'java' },
 { :from => 'client-yarn', :to => 'java' },
 { :from => 'presto_worker',     :to => 'compute' },
 { :from => 'presto_worker',     :to => 'user' },
 { :from => 'artifact',   :to => 'library' },
 { :from => 'artifact',   :to => 'presto_worker'  },
 { :from => 'artifact',   :to => 'download' },
 { :from => 'artifact',   :to => 'volume' },
 { :from => 'java',       :to => 'os' },
 { :from => 'java',       :to => 'download' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
             :relation_name => 'DependsOn',
             :from_resource => link[:from],
             :to_resource => link[:to],
             :attributes => { 'flex' => false, 'min' => 1, 'max' => 1 }
end

[{ :from => 'presto_coordinator_worker', :to => 'presto_worker' },
 { :from => 'presto_coordinator_worker', :to => 'client-yarn' },
 { :from => 'presto_mysql_worker', :to => 'presto_coordinator_worker' },
 { :from => 'presto_cassandra_worker', :to => 'presto_coordinator_worker' },
 { :from => 'presto_swift_worker', :to => 'presto_coordinator_worker' },
 { :from => 'presto_swift_worker', :to => 'client-yarn' }].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
             :relation_name => 'DependsOn',
             :from_resource => link[:from],
             :to_resource => link[:to],
             :attributes => { :propagate_to => 'from', 'flex' => false, 'min' => 1, 'max' => 1 }
end

[{ :from => 'client-yarn', :to => 'hadoop-yarn-config' }
   ].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}",
             :relation_name => 'DependsOn',
             :from_resource => link[:from],
             :to_resource => link[:to],
             :attributes => { :propagate_to => 'from', 'flex' => false, "converge" => true, 'min' => 1, 'max' => 1 }
end

relation "presto-cluster::depends_on::presto_worker",
         :except => [ '_default', 'single' ],
         :relation_name => 'DependsOn',
         :from_resource => 'presto-cluster',
         :to_resource   => 'presto_worker',
         :attributes    => { :propagate_to => 'from', "flex" => true, "min" => 1, "max" => 10 }

[ 'presto_coordinator_worker' ].each do |from|
  relation "#{from}::depends_on::presto_worker",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'presto_worker',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

[ 'presto_worker' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

relation "presto_worker::depends_on::presto",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => 'presto_worker',
    :to_resource   => 'presto',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "converge" => true, "min" => 1, "max" => 1 }

# managed_via
['presto_worker', 'java',
    'presto_coordinator_worker', 'presto_mysql_worker', 'presto_cassandra_worker',
    'presto_swift_worker', 'client-yarn' ].each do |from|
    relation "#{from}::managed_via::compute",
             :except => ['_default'],
             :relation_name => 'ManagedVia',
             :from_resource => from,
             :to_resource => 'compute',
             :attributes => {}
end
