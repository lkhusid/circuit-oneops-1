include_pack "generic_ring"

name "apache_cassandra"
description "Apache Cassandra"
type "Platform"
category "Database NoSQL"

platform :attributes => {'autoreplace' => 'false'}

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "1024 65535 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "apache_cassandra",
  :cookbook => "oneops.1.apache_cassandra",
  :design => true,
  :requires => {
      :constraint => "1..1",
      :services => "maven,mirror",
      :help => 'Cassandra Server'
    },
  :attributes => {
    "version"       => "3.9",
    "cluster"       => "TestCluster",
    "jvm_opts"      => '[
                        "-Xss256k",
                        "-XX:+UseParNewGC",
                        "-XX:+UseConcMarkSweepGC",
                        "-XX:+CMSParallelRemarkEnabled",
                        "-XX:SurvivorRatio=8",
                        "-XX:MaxTenuringThreshold=1",
                        "-XX:CMSInitiatingOccupancyFraction=75",
                        "-XX:+UseCMSInitiatingOccupancyOnly",
                        "-XX:+UseTLAB"]',
    "config_directives" => '{"max_hints_delivery_threads":"2",
                            "concurrent_writes":"32",
                            "commitlog_total_space_in_mb":"4096",
                            "memtable_flush_writers":"1",
                            "trickle_fsync":"false",
                            "trickle_fsync_interval_in_kb":"10240",
                            "rpc_server_type":"sync",
                            "concurrent_compactors":"1",
                            "compaction_throughput_mb_per_sec":"16",
                            "start_rpc":"true"
                            }'
  },
  :monitors => {
      'CheckProcess' => {
           :description => 'Cassandra Process',
           :source      => '',
           :chart       => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
           :cmd         => 'check_process!cassandra!true!/app/cassandra/cassandra.pid',
           :cmd_line    => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
           :metrics     => {
             'up' => metric(:unit => '%', :description => 'Percent Up'),
           },
           :thresholds  => {
             'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
           }
         },
       'Log' => {:description => 'Log',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_logfiles!logcassandra!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                 :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                 :cmd_options => {
                     'logfile' => '/opt/cassandra/logs/system.log',
                     'warningpattern' => 'WARN',
                     'criticalpattern' => 'ERROR'
                 },
                 :metrics => {
                     'logcassandra_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                     'logcassandra_errors' => metric(:unit => 'errors', :description => 'Errors', :dstype => 'GAUGE'),
                     'logcassandra_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                     'logcassandra_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                   'CriticalLogException' => threshold('1m', 'avg', 'criticals', trigger('>=', 10, 1, 1), reset('<', 10, 1, 1)),
                 }
       },
           'NodeStatus' => {
             :description => 'Nodetool Status',
             :source      => '',
             :chart => {'min'=>0},
             :cmd         => 'nodetool_status',
             :cmd_line    => '/opt/nagios/libexec/nodetool_status.pl',
             :metrics     => {
               'upnodes' => metric(:unit => 'upnodes', :description => 'Nodes that are UN', :dstype => 'GAUGE'),
               'downnodes' => metric(:unit => 'downnodes', :description => 'Nodes that are DN', :dstype => 'GAUGE'),
               'totalnodes' => metric(:unit => 'totalnodes', :description => 'Total Nodes', :dstype => 'GAUGE')
             },
             :thresholds  => {
              'DownNodes' => threshold('1m', 'avg', 'downnodes', trigger('>=', 1, 1, 1), reset('<', 1, 1, 1)),
             }
           },
           'PendingCompactions'  => {
             :description => 'Pending Compactions',
             :source      => '',
             :chart       => {'min' => 0, 'unit' => 'Per Second'},
             :cmd         => 'check_pending_tasks',
             :cmd_line    => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:7199/jmxrmi -O org.apache.cassandra.metrics:type=Compaction,name=PendingTasks -A Value',
             :metrics     => {
               'Value' => metric(:unit => 'Per Second', :description => 'Pending Compactions', :dstype => 'GAUGE'),
             },
             :thresholds  => {
              'Value' => threshold('5m', 'avg', 'Value', trigger('>=', 30, 5, 1), reset('<', 30, 5, 1)),
             }
           },
           'CommitLogSize' => {
             :description => 'CommitLogSize',
             :source      => '',
             :chart => {'min'=>0, 'max' => '100', 'unit' => 'Percent'},
             :cmd         => 'commit_log_size',
             :cmd_line    => '/opt/nagios/libexec/commit_log_size.pl',
             :metrics     => {
               'commitlogsize' => metric(:unit => '%', :description => 'Percent of commitlog_total_space used'),
             },
             :thresholds  => {
               'UsageExceeded' => threshold('1m', 'avg', 'commitlogsize', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
             }
           },
           'CheckSSTCount' => {
             :description => 'Check SSTable count',
             :source      => '',
             :chart => {'min'=>0},
             :cmd         => 'check_sst_sum',
             :cmd_line    => '/opt/nagios/libexec/check_sst_sum.pl',
             :metrics     => {
               'sst_table_count' => metric(:unit => 'sst_table_count', :description => 'Total Number of SSTables'),
             },
             :thresholds  => {
              'sst_table_count' => threshold('5m', 'avg', 'sst_table_count', trigger('>=', 100, 100, 100), reset('<', 100, 100, 100)),
             }
           },
           'ReadOperations'  => {
             :description => 'Read Operations',
             :source      => '',
             :chart       => {'min' => 0, 'unit' => 'Per Second'},
             :cmd         => 'check_cassandra_reads',
             :cmd_line    => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:7199/jmxrmi -O org.apache.cassandra.metrics:type=ClientRequest,scope=Read,name=Latency -A OneMinuteRate',
             :metrics     => {
               'OneMinuteRate' => metric(:unit => 'Per Second', :description => 'Read Operations', :dstype => 'GAUGE'),
             },
             :thresholds  => {
              'OneMinuteRate' => threshold('5m', 'avg', 'OneMinuteRate', trigger('>=', 10000, 1, 1), reset('<', 10000, 1, 1)),
             }
           },
           'RecentReadLatency'  => {
             :description => 'Recent Read Operations Latency',
             :source      => '',
             :chart       => {'min' => 0, 'unit' => 'Microseconds'},
             :cmd         => 'check_cassandra_read_latency',
             :cmd_line    => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:7199/jmxrmi -O org.apache.cassandra.metrics:type=ClientRequest,scope=Read,name=Latency -A 98thPercentile',
             :metrics     => {
               '98thPercentile' => metric(:unit => 'Microseconds', :description => 'Latency of All Read Operations', :dstype => 'GAUGE'),
             },
             :thresholds  => {
              '98thPercentile' => threshold('5m', 'avg', '98thPercentile', trigger('>=', 1000000, 1, 1), reset('<', 1000000, 1, 1)),
             }
           },
           'WriteOperations' => {
             :description => 'Write Operations',
             :source      => '',
             :chart       => {'min' => 0, 'unit' => 'Per Second'},
             :cmd         => 'check_cassandra_writes',
             :cmd_line    => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:7199/jmxrmi -O org.apache.cassandra.metrics:type=ClientRequest,scope=Write,name=Latency -A OneMinuteRate',
             :metrics     => {
               'OneMinuteRate' => metric(:unit => 'Per Second', :description => 'Write Operations', :dstype => 'GAUGE'),
             },
             :thresholds  => {
              'OneMinuteRate' => threshold('5m', 'avg', 'OneMinuteRate', trigger('>=', 10000, 1, 1), reset('<', 10000, 1, 1)),
             }
           },
           'RecentWriteLatency' => {
             :description => 'Recent Write Operations Latency',
             :source      => '',
             :chart       => {'min' => 0, 'unit' => 'Microseconds'},
             :cmd         => 'check_cassandra_write_latency',
             :cmd_line    => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:7199/jmxrmi -O org.apache.cassandra.metrics:type=ClientRequest,scope=Write,name=Latency -A 98thPercentile',
             :metrics     => {
               '98thPercentile' => metric(:unit => 'Microseconds', :description => 'Write Operations Latency', :dstype => 'GAUGE'),
             },
             :thresholds  => {
              '98thPercentile' => threshold('5m', 'avg', '98thPercentile', trigger('>=', 1000000, 1, 1), reset('<', 1000000, 1, 1)),
             }
           }
  },
  :payloads => {
    'clouds' => {
      'description' => 'Clouds',
      'definition' => '{
        "returnObject": false,
        "returnRelation": false,
        "relationName": "base.RealizedAs",
        "direction": "to",
        "targetClassName": "manifest.oneops.1.Apache_cassandra",
        "relations": [{ "returnObject": false,
          "returnRelation": false,
          "relationName": "manifest.Requires",
          "direction": "to",
          "targetClassName": "manifest.Platform",
          "relations": [{ "returnObject": true,
            "returnRelation": false,
            "returnRelationAttributes":true,
            "relationAttrs":[{
                "attributeName":"adminstatus",
                "condition":"eq", "avalue":"active"
              }],
            "relationName": "base.Consumes",
            "direction": "from",
            "targetClassName": "account.Cloud"
          }]
        }]
      }'
    },
    'computes' => {
      'description' => 'computes',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Apache_cassandra",
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
      }'
    },
   }

  #  'clouds' => {
  #   'description' => 'clouds',
  #   'definition' => '{
  #      "returnObject": false,
  #      "returnRelation": false,
  #      "relationName": "base.RealizedAs",
  #      "direction": "to",
  #      "targetClassName": "manifest.oneops.1.Apache_cassandra",
  #      "relations": [
  #        { "returnObject": false,
  #          "returnRelation": false,
  #          "relationName": "manifest.DependsOn",
  #          "direction": "from",
  #          "targetClassName": "manifest.oneops.1.Compute",
  #          "relations": [
  #             { "returnObject": false,
  #               "returnRelation": false,
  #               "relationName": "base.RealizedAs",
  #               "direction": "from",
  #               "targetClassName": "bom.oneops.1.Compute",
  #               "relations": [
  #                 { "returnObject": true,
  #                   "returnRelation": false,
  #                   "relationName": "base.DeployedTo",
  #                   "direction": "from",
  #                   "targetClassName": "account.Cloud"
  #                 }
  #               ]

  #             }
  #           ]

  #        }
  #      ]
  #   }'
  # }

# overwrite volume from generic_ring to make them mandatory
resource "volume",
  :requires => { "constraint" => "1..*", "services" => "compute" },
  :attributes => {  "mount_point"   => '/app/cassandra',
                    "device"        => '',
                    "fstype"        => 'xfs',
                    "options"       => ''
                 },
  :monitors => {
      'disk_usage' =>  {'description' => 'Disk Usage',
                  'chart' => {'min'=>0,'unit'=> 'Percent used'},
                  'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                  'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                  'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                 'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                  :thresholds => {
                    'LowDiskSpace' => threshold('5m', 'avg', 'space_used' ,trigger('>', 35, 5, 1),reset('<', 33, 5, 1)),
                    'CriticalDiskSpace' => threshold('5m', 'avg', 'space_used' ,trigger('>', 42, 10, 1),reset('<', 40, 10, 1), 'overutilized'),
                    'Underutilized' => threshold('5m', 'avg', 'space_used' ,trigger('<', 10, 10, 1),reset('>=', 10, 10, 1),)
                  },
                },
    }

resource 'keyspace',
         :cookbook => 'oneops.1.keyspace',
         :design => true,
         :requires => { :constraint => '0..*'},
         :attributes => {
           :keyspace_name =>'$OO_LOCAL{keyspaceName}',
           :replication_factor => 3,
           :placement_strategy => 'NetworkTopologyStrategy',
           :extra => ''
         },
       :payloads => {
	      'keyspace_clouds' => {
			'description' => 'keyspace_clouds',
			'definition' => '{
			 "returnObject": false,
			 "returnRelation": false,
			 "relationName": "base.RealizedAs",
			 "direction": "to",
			 "targetClassName": "manifest.oneops.1.Keyspace",
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
			         "direction": "from",
			         "targetClassName": "account.Cloud"
			       }
			     ]
			   }
			 ]
			}'
		},
  'Keyspace_Cassandra' => {
  'description' => 'Cassandra',
  'definition' => '{
     "returnObject": false,
     "returnRelation": false,
     "relationName": "base.RealizedAs",
     "direction": "to",
     "targetClassName": "manifest.oneops.1.Keyspace",
     "relations": [
       { "returnObject": false,
         "returnRelation": false,
         "relationName": "manifest.Requires",
         "direction": "to",
         "targetClassName": "manifest.Platform",
         "relations": [
           { "returnObject": true,
             "returnRelation": false,
             "relationName": "manifest.Requires",
             "direction": "from",
             "targetClassName": "manifest.oneops.1.Apache_cassandra"
           }
         ]
       }
     ]
  }'
 }
 }

resource 'user-cassandra',
         :cookbook   => 'oneops.1.user',
         :design     => true,
         :requires   => {:constraint => '1..1'},
         :attributes => {
           :username        => 'cassandra',
           :home_directory  => '/home/cassandra',
           :description     => 'Cassandra User',
           :system_account  => false,
           :sudoer          => true,
           :authorized_keys => '["ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAr2jXW4cjVlTAZqaHLeKqMzd1MpBjGOSjoidKmOmj5Jmv99MQ+iXwXo3hHoFrThtoi4qVQ61R1koUUaiip/eiTD1nYqCKOVF+jP2IYoWecJZdPGcR0sBlyD2/3MVzV7iQWBTgJt5IvMC4J7aZ/0F2J98Ag7sKzTNoUSr9DsajCo129VgOloRWddndN/UvpiUKHMmxfB4qE/z+W53KhJQLBluGY9AY2klJxdJ4Dfuay2bmXHKFxn39tWAUJ9lWxjFiHi+09ZycFSbG8jUtFEbCcHiVjpgkrDdaywv0nb600OW9nJFrdTlt745ReBOAI8BH9wmzu0OXEr2a22uDFpNa3Q== cassandra"]'
         }

resource "java",
         :cookbook => "oneops.1.java",
         :design => true,
         :requires => {
             :constraint => "1..1",
             :services => '*mirror',
             :help => "Java Programming Language Environment"
         },
         :attributes => {
             :jrejdk => "jdk",
             :version => "8",
             :sysdefault => "true",
             :flavor => "oracle"
         }

resource "artifact",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => { "constraint" => "0..*" },
         :attributes => {

         },
         :monitors => {
             'URL' => {:description => 'URL',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
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

                       }
             },
             'exceptions' => {:description => 'Exceptions',
                              :source => '',
                              :chart => {'min' => 0, 'unit' => ''},
                              :cmd => 'check_logfiles!logexc!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                              :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol  --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                              :cmd_options => {
                                  'logfile' => '/log/logmon/logmon.log',
                                  'warningpattern' => 'Exception',
                                  'criticalpattern' => 'Exception'
                              },
                              :metrics => {
                                  'logexc_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                                  'logexc_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                                  'logexc_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                                  'logexc_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                              },
                              :thresholds => {
                                  'CriticalExceptions' => threshold('15m', 'avg', 'logexc_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1))
                              }
             }
         }

resource "jolokia_proxy",
         :cookbook => "oneops.1.jolokia_proxy",
         :design => true,
         :requires => {
           "constraint" => "0..1",
           :services => "mirror"
         },
         :monitors => {
           'JolokiaProxyProcess' => {
             :description => 'JolokiaProxyProcess',
             :source => '',
             :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
             :cmd => 'check_process!jolokia_proxy!false!/opt/metrics_collector/jetty_base/jetty.state',
             :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
             :metrics => {
               'up' => metric(:unit => '%', :description => 'Percent Up'),
             },
             :thresholds => {
               'JolokiaProxyProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
             }
           }
         }

# depends_on
[ { :from => 'apache_cassandra', :to => 'os' },
  { :from => 'volume', :to => 'os'},
  { :from => 'user-cassandra', :to => 'volume'},
  { :from => 'apache_cassandra', :to => 'volume' },
  { :from => 'apache_cassandra', :to => 'user-cassandra' },
  { :from => 'java', :to => 'os' },
  { :from => 'apache_cassandra', :to => 'java' },
  { :from => 'daemon',    :to => 'apache_cassandra'  },
  { :from => 'artifact',  :to => 'apache_cassandra'  },
  { :from => 'daemon',    :to => 'artifact'  },
  {:from => 'jolokia_proxy', :to => 'compute'},
  {:from => 'java', :to => 'compute'},
  {:from => 'jolokia_proxy', :to => 'java'},
  {:from => 'apache_cassandra', :to => 'telegraf' },
  {:from => 'apache_cassandra', :to => 'compute' }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "ring::depends_on::apache_cassandra",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'ring',
    :to_resource   => 'apache_cassandra',
    :attributes    => { :propagate_to => 'from', "flex" => true, "min" => 3, "max" => 10 }

relation 'fqdn::depends_on::ring',
         :except        => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'fqdn',
         :to_resource   => 'ring',
         :attributes    => {:propagate_to => 'from', :flex => false, :min => 1, :max => 1}

relation 'fqdn::depends_on::compute',
         :only          => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'fqdn',
         :to_resource   => 'compute',
         :attributes    => {:flex => false, :min => 1, :max => 1}

relation "apache_cassandra::depends_on::java",
    :relation_name => 'DependsOn',
    :from_resource => 'apache_cassandra',
    :to_resource   => 'java',
    :attributes    => { :propagate_to => 'from', "flex" => false, "min" => 1, "max" => 1}

relation "keyspace::depends_on::apache_cassandra",
    :except => ['redundant'],
    :relation_name => 'DependsOn',
    :from_resource => 'keyspace',
    :to_resource   => 'apache_cassandra',
    :attributes    => { :propagate_to => 'from', "flex" => false, "min" => 0, "max" => 1}

relation 'keyspace::depends_on::ring',
    :except        => ['_default', 'single'],
    :relation_name => 'DependsOn',
    :from_resource => 'keyspace',
    :to_resource   => 'ring',
    :attributes    => {:propagate_to => 'from', :flex => false, :min => 0, :max => 1}


['user-cassandra','java', 'jolokia_proxy', 'apache_cassandra', 'artifact'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

relation 'ring::managed_via::compute',
         :except        => ['_default', 'single'],
         :relation_name => 'ManagedVia',
         :from_resource => 'ring',
         :to_resource   => 'compute',
         :attributes    => {}

['keyspace'].each do |from|
  relation "#{from}::managed_via::ring",
    :except => [ '_default', 'single' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'ring',
    :attributes    => { }
end

# securedBy
['ring'].each do |from|
  relation "#{from}::secured_by::sshkeys",
           :except        => ['_default', 'single'],
           :relation_name => 'SecuredBy',
           :from_resource => from,
           :to_resource   => 'sshkeys',
           :attributes    => {}
end

procedure "nodetool_repair",
  :description => "Cassandra nodetool repair",
  :arguments => {
        "nodetool repair arguments" => {
                "name" => "repair_args",
                "defaultValue" => "-pr",
                "dataType" => "string"
        }
   },
   :definition => '{
    "flow": [
        {
            "execStrategy": "one-by-one",
            "relationName": "manifest.Requires",
            "direction": "from",
            "targetClassName": "manifest.oneops.1.Apache_cassandra",
            "flow": [
                {
                    "relationName": "base.RealizedAs",
                    "execStrategy": "one-by-one",
                    "direction": "from",
                    "targetClassName": "bom.walmartlabs.Apache_cassandra",
                    "actions": [
                        {
                            "actionName": "nodetool_repair",
                            "stepNumber": 1,
                            "isCritical": true
                        }
                    ]
                }
            ]
        }
    ]
}'
