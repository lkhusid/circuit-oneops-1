include_pack "generic_ring"

name "kafka"
description "Kafka"
type "Platform"
category "Messaging"

platform :attributes => {
         'availability' => 'redundant',
         'autoreplace' => 'false'
}
resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0", "9091 9091 tcp 0.0.0.0/0","2888 2888 tcp 0.0.0.0/0","3888 3888 tcp 0.0.0.0/0","9092 9092 tcp 0.0.0.0/0", "9093 9093 tcp 0.0.0.0/0", "9000 9000 tcp 0.0.0.0/0", "9097 9097 tcp 0.0.0.0/0", "11061 11064 tcp 0.0.0.0/0", "8449 8449 udp 0.0.0.0/0", "8000 8000 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "os",
  :cookbook => "oneops.1.os",
  :attributes => { 
       "ostype"  => "centos-7.2",
       "limits" => '{"nofile": 16384}',
       "sysctl"  => '{"net.ipv4.tcp_mem":"3064416 4085888 6128832", "net.ipv4.tcp_rmem":"4096 1048576 16777216", "net.ipv4.tcp_wmem":"4096 1048576 16777216", "net.core.rmem_max":"16777216", "net.core.wmem_max":"16777216", "net.core.rmem_default":"1048576", "net.core.wmem_default":"1048576", "fs.file-max":"1048576"}',
             "dhclient"  => 'true' }
  
resource 'compute',
         :cookbook => 'oneops.1.compute',
         :requires => { "constraint" => "1..1", "services" => "compute,dns,*mirror" },
         :attributes => {'size' => 'L-MEM' }
         
resource "os-console",
  :cookbook => "oneops.1.os",
  :design => true, 
  :requires => { "constraint" => "1..1", "services" => "compute,dns,*ntp" },
  :attributes => { 
       "ostype"  => "centos-7.2",
       "limits" => '{"nofile": 16384}',
       "sysctl"  => '{"net.ipv4.tcp_mem":"3064416 4085888 6128832", "net.ipv4.tcp_rmem":"4096 1048576 16777216", "net.ipv4.tcp_wmem":"4096 1048576 16777216", "net.core.rmem_max":"16777216", "net.core.wmem_max":"16777216", "net.core.rmem_default":"1048576", "net.core.wmem_default":"1048576", "fs.file-max":"1048576"}',
             "dhclient"  => 'true' }
  
resource 'compute-console',
  :design => true,
  :cookbook => 'oneops.1.compute',
  :requires => { "constraint" => "1..1" , "services" => "compute,dns,*mirror" },
  :attributes => {'size' => 'L'},
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
    },
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


resource "kafka",
         :cookbook => "oneops.1.kafka",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "mirror"},
         :monitors => {
             'kafkaprocess' => {:description => 'KafkaProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!kafka!true!kafka.Kafka',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'KafkaProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                           }
             },
            'jmxprocess' => {:description => 'JmxProcess',
                 :source => '',
                 :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                 :cmd => 'check_process!jmxtrans!false!jmxtrans',
                 :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                 :metrics => {
                     'up' => metric(:unit => '%', :description => 'Percent Up'),
                 },
                 :thresholds => {
                     'JmxProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                 }
             },
#               'kafkazkconn' => {:description => 'KafkaZKConn',
#                  :source => '',
#                  :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
#                  :cmd => 'check_kafka_zk_conn',
#                  :cmd_line => '/opt/nagios/libexec/check_kafka_zk_conn.sh',
#                  :metrics => {
#                      'up' => metric(:unit => '%', :description => 'Percent Up'),
#                  },
#                  :thresholds => {
#                      'KafkaZookeeperConnection' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
#                  }
#              },
              'KafkaLog' => {:description => 'Kafka Log',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_logfiles!logkafka!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                 :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                 :cmd_options => {
                     'logfile' => '/var/log/kafka/server.log',
                     'warningpattern' => 'WARN',
                     'criticalpattern' => 'ERROR'
                 },
                 :metrics => {
                     'logkafka_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                     'logkafka_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                     'logkafka_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                     'logkafka_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                     'CriticalKafkaLogException' => threshold('1m', 'avg', 'logkafka_criticals', trigger('>=', 20, 1, 1), reset('<', 20, 5, 1)),
                     'WarningKafkaLogException' => threshold('1m', 'avg', 'logkafka_warnings', trigger('>=', 20, 1, 1), reset('<', 20, 5, 1)),
                 }
             }
          }

resource "kafka-console",
     :cookbook => "oneops.1.kafka_console",
	 :design => true,
         :requires => {"constraint" => "1..1", "services" => "dns,*mirror"},
	 :attributes => {
	 },
     :payloads => {
      'kafka' => {
        :description => 'Kafka',
        :definition  => '{
        "returnObject": false,
        "returnRelation": false,
        "relationName": "bom.DependsOn",
        "direction": "from",
        "targetClassName": "bom.oneops.1.Volume",
        "relations": [
        {"returnObject": false,
            "returnRelation": false,
            "relationName": "bom.DependsOn",
            "direction": "from",
            "targetClassName": "bom.oneops.1.Os",
            "relations": [
         {"returnObject": false,
            "returnRelation": false,
            "relationName": "bom.DependsOn",
            "direction": "from",
            "targetClassName": "bom.oneops.1.Compute",
            "relations": [
            {"returnObject": false,
                "returnRelation": false,
                "relationName": "bom.DependsOn",
                "direction": "from",
                "targetClassName": "bom.oneops.1.Ring",
                "relations": [
                {"returnObject": true,
                    "returnRelation": false,
                    "relationName": "bom.DependsOn",
                    "direction": "from",
                    "targetClassName": "bom.oneops.1.Kafka"
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
    },
	 :monitors => {
	    'kafkamanagerprocess' => {:description => 'KafkaManagerProcess',
             :source => '',
			 :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
			 :cmd => 'check_process!kafka-manager!true!kafka-manager',
			 :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
			 :metrics => {
	             'up' => metric(:unit => '%', :description => 'Percent Up'),
             },
			 :thresholds => {
	           'KafkaManagerProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
             }
        },
        'nginxprocess' => {:description => 'NginxProcess',
            :source => '',
            :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
            :cmd => 'check_process!nginx!true!nginx',
            :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
            :metrics => {
                'up' => metric(:unit => '%', :description => 'Percent Up'),
            },
            :thresholds => {
                'NginxProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
            }
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

resource "user-kafka",
         :cookbook => "oneops.1.user",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             "username" => "kafka",
             "description" => "App User",
             "home_directory" => "/home/kafka",
             "system_account" => true,
             "sudoer" => true
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

# enable ptr of FQDN, keep ptr_source as "platform" as default
resource "fqdn",
    :attributes => {
        :ptr_enabled => "true"
}

resource "storage",
  :cookbook => "oneops.1.storage",
  :design => true,
  :requires => { "constraint" => "0..1", "services" => "compute,storage" },
  :attributes => {
    "size"        => '10G',
    "slice_count" => '1'
}

resource "volume-persistent",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => {"constraint" => "0..1", "services" => "compute,storage"},
  :attributes => {:mount_point => '/data',
    :size => '100%FREE',
    :device => '',
    :fstype => 'ext4',
    :options => ''
},
:monitors => {
    'usage' => {'description' => 'Usage',
        'chart' => {'min' => 0, 'unit' => 'Percent used'},
        'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
        'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
        'metrics' => {'space_used' => metric(:unit => '%', :description => 'Disk Space Percent Used'),
            'inode_used' => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
        :thresholds => {
            'LowDiskSpace' => threshold('1m', 'avg', 'space_used', trigger('>=', 60, 5, 2), reset('<', 55, 5, 1)),
            'LowDiskInode' => threshold('1m', 'avg', 'inode_used', trigger('>=', 60, 5, 2), reset('<', 55, 5, 1))
        }
    }
}

resource "volume",
  :cookbook => "oneops.1.volume",
  :requires => { "constraint" => "0..1", "services" => "compute" }

resource "volume-kafka",
  :cookbook => "oneops.1.volume",
  :design => true,
  :requires => { "constraint" => "1..1", "services" => "compute" },
  :attributes => {  "mount_point"   => '/kafka',
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
                    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',60,5,1),reset('<',55,5,1)),
                    'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',60,5,1),reset('<',55,5,1)),
                  },
                }
    }

resource "keystore",
         :cookbook => "oneops.1.keystore",
         :design => true,
         :requires => {"constraint" => "0..1"},
         :attributes => {
             "keystore_filename" => "/var/lib/certs/kafka.server.keystore.jks"
         }

resource "client-certs-download",
         :cookbook => "oneops.1.download",
         :design => true,
         :requires => {
             :constraint => "0..*",
         },
         :attributes => {
             :source => '',
             :basic_auth_user => "",
             :basic_auth_password => "",
             :path => '',
             :post_download_exec_cmd => ''
         }

# optional for jolokia_proxy
resource "jolokia_proxy",
  :cookbook => "oneops.1.jolokia_proxy",
  :design => true,
  :requires => {
    "constraint" => "0..1",
    :services => "*mirror"
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
  {:from => 'hostname', :to => 'os'},
  {:from => 'volume-kafka', :to => 'os'},
  {:from => 'volume-kafka', :to => 'compute'},
  {:from => 'user-kafka', :to => 'os'},
  {:from => 'client-certs-download', :to => 'os'},
  {:from => 'java', :to => 'os'},
  {:from => 'artifact', :to => 'os'},
  {:from => 'storage', :to => 'os'},
  {:from => 'jolokia_proxy', :to => 'java'  },
  {:from => 'artifact', :to => 'user-kafka'},
  {:from => 'volume-persistent', :to => 'storage'},
  {:from => 'kafka', :to => 'volume-persistent'},
  {:from => 'kafka', :to => 'user-kafka'},
  {:from => 'user-kafka', :to => 'volume-kafka'},
  {:from => 'kafka', :to => 'java'},
  {:from => 'kafka', :to => 'hostname'},
  {:from => 'kafka', :to => 'certificate'},
  {:from => 'kafka', :to => 'keystore'},
  {:from => 'keystore', :to => 'certificate'},
  {:from => 'os', :to => 'compute'},
  
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end
# 
# # propagation rule for replace
# [ 'fqdn' ].each do |from|
#   relation "#{from}::depends_on::compute",
#     :relation_name => 'DependsOn',
#     :from_resource => from,
#     :to_resource   => 'compute',
#     :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
# end

relation "ring::depends_on::kafka",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'ring',
    :to_resource   => 'kafka',
    :attributes    => { "flex" => true, "min" => 3, "max" => 10 }

# managed_via
# [ 'kafka'].each do |from|
#   relation "#{from}::managed_via::compute",
#     :except => [ '_default' ],
#     :relation_name => 'ManagedVia',
#     :from_resource => from,
#     :to_resource   => 'compute',
#     :attributes    => { }
# end

# resource "build",
#   :cookbook => "oneops.1.build",
#   :design => true,
#   :requires => { "constraint" => "0..*" }
# 
# resource "ring",
#   :except => [ 'single' ],
#   :cookbook => "oneops.1.ring",
#   :design => false,
#   :requires => { "constraint" => "1..1" }
# 
# # ManagedVia
# [ 'ring', 'build' ].each do |from|
#   relation "#{from}::managed_via::compute",
#     :except => [ '_default', 'single' ],
#     :relation_name => 'ManagedVia',
#     :from_resource => from,
#     :to_resource   => 'compute',
#     :attributes    => { }
# end

# managed_via
['os','user-kafka', 'artifact', 'kafka', 'java', 'library','volume-kafka', 'volume-persistent', 'keystore', 'client-certs-download', 'jolokia_proxy'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end

relation "compute-console::depends_on::secgroup",
    :relation_name => 'DependsOn',
    :from_resource => 'compute-console',
    :to_resource   => 'secgroup',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }

relation "compute-console::depends_on::ring",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'compute-console',
    :to_resource   => 'ring',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }

relation "fqdn::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => 'fqdn',
    :to_resource   => 'compute-console',
    :attributes    => {"propagate_to" => 'both', "flex" => false, "min" => 1, "max" => 1 }

# secured_by
[ 'compute-console'].each do |from|
   relation "#{from}::secured_by::sshkeys",
       :except => [ '_default' ],
       :relation_name => 'SecuredBy',
       :from_resource => from,
       :to_resource   => 'sshkeys',
       :attributes    => { }
 end

resource "user-console",
     :cookbook => "oneops.1.user",
     :design => true,
     :requires => {"constraint" => "1..1"},
     :attributes => {
        "username" => "app",
        "description" => "App User",
        "home_directory" => "/app",
        "system_account" => true,
        "sudoer" => true
     }
resource "java-console",
     :cookbook => "oneops.1.java",
     :design => true,
     :requires => {
        :constraint => "1..1",
        :help => "Java Programming Language Environment",
        :services => '*mirror'
     },
     :attributes => {
              :install_dir => "/usr/lib/jvm",
              :jrejdk => "jdk",
              :binpath => "",
              :version => "8",
              :sysdefault => "true",
              :flavor => "oracle"
          }

resource "volume-console",
    :cookbook => "oneops.1.volume",
    :design => true,
    :requires => { "constraint" => "1..1", "services" => "compute" },
    :attributes => {  "mount_point"   => '/console',
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
                  'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                  'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
            },
           }
     }
[
  { :from => 'java-console',     :to => 'os-console'  },
  { :from => 'kafka-console',        :to => 'volume-console' },
  { :from => 'volume-console',        :to => 'os-console' },
  { :from => 'kafka-console',        :to => 'fqdn' },
  { :from => 'user-console',        :to => 'volume-console' },
  {:from => 'kafka-console', :to => 'java-console'},
  {:from => 'os-console', :to => 'compute-console'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
      :relation_name => 'DependsOn',
      :from_resource => link[:from],
      :to_resource   => link[:to],
      :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
   end

[ "os-console",'volume-console', 'user-console', 'kafka-console', 'java-console'].each do |from|
  relation "#{from}::managed_via::compute-console",
        :except => [ '_default' ],
        :relation_name => 'ManagedVia',
        :from_resource => from,
        :to_resource   => 'compute-console',
        :attributes    => { }	
     end

