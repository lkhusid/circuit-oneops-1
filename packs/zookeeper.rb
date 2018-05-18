include_pack 'generic_ring'

name "zookeeper"
description "Zookeeper"
type "Platform"
category "Other"

platform :attributes => {'autoreplace' => 'false'}

environment "single", {}
environment "redundant", {}

variable "install_dir",
         :description => 'Zookeeper installation directory',
         :value => '/usr/lib/zookeeper'

variable "version",
         :description => 'Zookeeper version',
         :value => '3.4.6'

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "2181 2182 tcp 0.0.0.0/0","9091 9091 tcp 0.0.0.0/0","2888 2888 tcp 0.0.0.0/0","3888 3888 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "zookeeper",
         :cookbook => "oneops.1.zookeeper",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             'mirror' => "$OO_CLOUD{nexus}/service/local/repositories/thirdparty/content/org/apache/zookeeper/",
             'install_dir' => "$OO_LOCAL{install_dir}",
             'version' => "$OO_LOCAL{version}",
             'jvm_args' => "-Xmx4g",
             'initial_timeout_ticks' => "10",
             'sync_timeout_ticks' => "5",
             'max_session_timeout' => "40000",
             'max_client_connections' => "60",
             'autopurge_snapretaincount' => "10",
             'autopurge_purgeinterval' => "6"
             },
          :monitors => {
             'zookeeperprocess' => {:description => 'ZookeeperProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!zookeeper-server!false!QuorumPeerMain',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'ZookeeperProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                           }
             },
            'cluster_health' =>  {'description' => 'Cluster Health',
                  'chart' => {'min'=>0,'unit'=> 'Number'},
                  'cmd' => 'check_cluster_health',
                  'cmd_line' => '/opt/nagios/libexec/check_cluster_health.sh',
                  'metrics' => {
                        'return_code' => metric(:unit => 'count', :description => 'Return Code from script'),
                                 },
                  :thresholds => {
                    'ClusterHealth' => threshold('1m','avg','return_code',trigger('>',1,1,1),reset('<',1,1,1))
                  },
             },
            'ZkLog' => {:description => 'Zk Log',               
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_logfiles!logzk!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                 :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                 :cmd_options => {
                     'logfile' => '/var/log/zookeeper/zookeeper.log',
                     'warningpattern' => 'WARN',
                     'criticalpattern' => 'not running|ERROR'
                 },
                 :metrics => {
                     'logzk_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                     'logzk_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                     'logzk_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                     'logzk_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                     'CriticalZkLogException' => threshold('5m', 'avg', 'logzk_criticals', trigger('>=', 5, 5, 1), reset('<', 1, 5, 1)),
                     'WarningZkLogException' => threshold('5m', 'avg', 'logzk_warnings', trigger('>=', 50, 5, 1), reset('<', 10, 5, 1)),
                 }
             }
          },
          :payloads => {
           'Clouds_in_zk_cluster' => {
               'description' => 'Clouds in Zookeeper cluster',
               'definition' => '{
                   "returnObject": false,
                   "returnRelation": false,
                   "relationName": "base.RealizedAs",
                   "direction": "to",
                   "targetClassName": "manifest.Zookeeper",
                   "relations": [
                     {
                       "returnObject": false,
                       "returnRelation": false,
                       "relationName": "manifest.Requires",
                       "direction": "to",
                       "targetClassName": "manifest.Platform",
                       "relations": [
                           {
                               "returnObject": true,
                               "returnRelation": false,
                               "relationAttrs":[{
                                   "attributeName":"adminstatus",
                                   "condition":"eq", "avalue":"active"
                               }],
                               "relationName": "base.Consumes",
                               "direction": "from",
                               "targetClassName": "account.Cloud"
                           }
                       ]
                   }]
               }'
           },
           'Computes_in_zk_cluster' => {
              'description' => 'Computes in Zookeeper cluster',
              'definition' => '{
                "returnObject": false,
                "returnRelation": false,
                "relationName": "base.RealizedAs",
                "direction": "to",
                "targetClassName": "manifest.Zookeeper",
                "relations": [
                  {
                    "returnObject": false,
                    "returnRelation": false,
                    "relationName": "manifest.DependsOn",
                    "direction": "from",
                    "targetClassName": "manifest.Compute",
                    "relations": [
                      {
                        "returnObject": true,
                        "returnRelation": false,
                        "relationName": "base.RealizedAs",
                        "direction": "from",
                        "targetClassName": "bom.oneops.1.Compute"
                       }
                     ]
                   }
                 ]
              }'
          }
        }

resource "artifact",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => {
             :constraint => "0..*",
             :help => "Artifact component"
         },
         :attributes => {
         }

resource "user-zookeeper",
         :cookbook => "oneops.1.user",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             "username" => "zookeeper",
             "description" => "App User",
             "home_directory" => "/zookeeper",
             "system_account" => true,
             "sudoer" => true
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
              :install_dir => "/usr/lib/jvm",
              :jrejdk => "jdk",
              :binpath => "",
              :version => "8",
              :sysdefault => "true",
              :flavor => "oracle"
          }

resource "hostname",
        :cookbook => "oneops.1.fqdn",
        :design => true,
        :requires => {
             :constraint => "1..1",
             :services => "dns",
             :help => "optional hostname dns entry"
         },
        # enable ptr and change ptr_source to 'instance'
        :attributes => {
           :ptr_enabled => "true",
           :ptr_source => "instance"
        }

resource "volume",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "0..*", "services" => "compute" },
  :attributes => {  "mount_point"   => '/data',
                    "size"          => '100%FREE',
                    "device"        => '',
                    "fstype"        => 'ext4',
                    "options"       => ''
                 },
  :monitors => {
      'usage' =>  {'description' => 'Usage',
                  'chart' => {'min'=>0,'unit'=> 'Percent used'},
                  'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                  'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                  'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                 'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                  :thresholds => {
                    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',80,5,1),reset('<',70,5,1)),
                    'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',80,5,1),reset('<',70,5,1)),
                  },
                }
    }

resource "diskcleanup-job",
  :cookbook => "oneops.1.job",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :help => "Run schedule cron job"
  },
  :attributes => {
    :user => 'zookeeper',
    :description => 'CRON to clean up older inodes',
    :minute => "0",
    :hour => "22",
    :day => "*",
    :month => "*",
    :weekday => "*",
    :cmd => '$OO_LOCAL{install_dir}/zookeeper-$OO_LOCAL{version}/bin/zkCleanup.sh 5'
}

resource "jolokia_proxy",
  :cookbook => "oneops.1.jolokia_proxy",
  :design => true,
  :requires => {
    "constraint" => "0..1",
    :services => "mirror"
  },
  :attributes => {
    version => "0.1"
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
            'JolokiaProxyProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
        }
    }
}

# depends_on
[
  {:from => 'user-zookeeper', :to => 'volume'},
  {:from => 'volume', :to => 'os'},
  {:from => 'user-zookeeper', :to => 'os'},
  {:from => 'zookeeper', :to => 'user-zookeeper'},
  {:from => 'zookeeper', :to => 'os'},
  {:from => 'artifact', :to => 'user-zookeeper'},
  {:from => 'artifact', :to => 'os'},
  {:from => 'zookeeper', :to => 'hostname'},
  {:from => 'zookeeper', :to => 'java'},
  {:from => 'java', :to => 'os'},
  {:from => 'diskcleanup-job', :to => 'os'},
  {:from => 'diskcleanup-job', :to => 'volume'},
  {:from => 'jolokia_proxy', :to => 'java'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" =>1 }
end

# propagation rule for replace
[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

relation "ring::depends_on::zookeeper",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'ring',
    :to_resource   => 'zookeeper',
    :attributes    => {"flex" => true, "min" => 1, "max" => 10 }

# managed_via
[ 'zookeeper'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

resource "build",
  :cookbook => "oneops.1.build",
  :design => true,
  :requires => { "constraint" => "0..*" }

resource "ring",
  :except => [ 'single' ],
  :cookbook => "oneops.1.ring",
  :design => false,
  :requires => { "constraint" => "1..1" }

# DependsOn
[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::ring",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'ring',
    :attributes    => { "propagate_to" => 'from',"flex" => false, "min" => 1, "max" => 1 }
end

# ManagedVia
[ 'ring', 'build' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default', 'single' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
# managed_via
['jolokia_proxy','diskcleanup-job','user-zookeeper', 'artifact', 'zookeeper', 'java', 'library', 'volume'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
