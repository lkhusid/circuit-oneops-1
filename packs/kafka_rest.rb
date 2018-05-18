include_pack "genericlb"

name          "kafka_rest"
description   "Kafka Rest Proxy"
type          "Platform"
category      "Other"

platform :attributes => {'autoreplace' => 'false'}

variable "kafkaconnecturl",
         :description => 'Kafka Connect Url',
         :value => '## Please specify the  Zookeeper connect url (server:port) ##'
         
variable "zkconnecturl",
         :description => 'Zookeeper Connect Url',
         :value => '## Please specify the  kafka connect url (server:port) ##'

variable "port",
         :description => 'Port to listen on for new connections',
         :value => '8082'

variable "jmxPort",
         :description => 'Port to listen on for JMX RMI connections',
         :value => '7199'

resource "lb",
  :except => [ 'single' ],
  :design => false,
  :attributes => {
    "listeners" => "[\"http 80 http $OO_LOCAL{port}\"]",
    "ecv_map"   => "{\"$OO_LOCAL{port}\":\"GET /\"}"
  }

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "$OO_LOCAL{port} $OO_LOCAL{port} tcp 0.0.0.0/0", "7199 7200 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "user-kafkarest",
         :cookbook => "oneops.1.user",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             "username" => "kafkarest",
             "description" => "Kafka Rest Proxy User",
             "home_directory" => "/kafka-rest",
             "system_account" => true,
             "sudoer" => true
         }
         
resource 'compute',
         :attributes => {
             "size"    => "L",
           }
         
resource "os",
  :cookbook => "oneops.1.os",
  :attributes => { 
       "ostype"  => "centos-7.2",
       "limits" => '{"nofile": 16384}',
       "sysctl"  => '{"net.ipv4.tcp_mem":"3064416 4085888 6128832", "net.ipv4.tcp_rmem":"4096 1048576 16777216", "net.ipv4.tcp_wmem":"4096 1048576 16777216", "net.core.rmem_max":"16777216", "net.core.wmem_max":"16777216", "net.core.rmem_default":"1048576", "net.core.wmem_default":"1048576", "fs.file-max":"1048576"}',
             "dhclient"  => 'true'
		}
		
resource "volume-kafkarest",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "compute"},
         :attributes => {"mount_point" => '/kafkarest',
                         "size" => '100%FREE',
                         "device" => '',
                         "fstype" => 'ext4',
                         "options" => ''
         },
         :monitors => {
             'usage' => {'description' => 'Usage',
                         'chart' => {'min' => 0, 'unit' => 'Percent used'},
                         'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                         'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                         'metrics' => {'space_used' => metric(:unit => '%', :description => 'Disk Space Percent Used'),
                                       'inode_used' => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
                          :thresholds => {
                    	    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                            'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                          },  
             }
         }

resource "hostname",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :services => "dns",
    :help => "optional hostname dns entry"
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
  
         
resource "kafka_rest",
         :cookbook => "oneops.1.kafka_rest",
         :design => true,
         :requires => {"constraint" => "1..1" , "services" => "mirror"},
         :attributes => {
         },
         :monitors => {
             'kafkarestprocess' => {:description => 'Process',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!kafka-rest!true!io.confluent.kafkarest.Main',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'kafkarestprocess' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                           }
             },
             'kafkarestlog' => {:description => 'Log',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_logfiles!logkafkarest!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                 :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                 :cmd_options => {
                    'logfile' => '/var/log/kafka-rest/kafka-rest.log',
                     'warningpattern' => 'WARN',
                     'criticalpattern' => 'ERROR'
                 },
                 :metrics => {
                     'logkafkarest_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                     'logkafkarest_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                     'logkafkarest_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                     'logkafkarest_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                     'CriticalKafkaRestLogException' => threshold('15m', 'avg', 'logkafkarest_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1)),
                 }
             },
             'ActiveConnections' =>  { :description => 'Active Connections',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Per Second'},
                  :cmd => 'ActiveConnections!:::node.workorder.rfcCi.ciAttributes.jmx_port:::',
                  :cmd_line => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:$OO_LOCAL{jmxPort}/jmxrmi -O kafka.rest:type=jetty-metrics -A connections-active',
                  :metrics =>  {
                    'connections-active'   => metric( :unit => 'per second', :description => 'Active Connections', :dstype => 'DERIVE')
                  },
                  :thresholds => {
                  }
             },
             'OpenedConnectionRate' =>  { :description => 'Opened Connection Rate',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Per Second'},
                  :cmd => 'OpenedConnectionRate!:::node.workorder.rfcCi.ciAttributes.jmx_port:::',
                  :cmd_line => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:$OO_LOCAL{jmxPort}/jmxrmi -O kafka.rest:type=jetty-metrics -A connections-opened-rate',
                  :metrics =>  {
                    'connections-opened-rate'   => metric( :unit => 'per second', :description => 'Opened Connection Rate', :dstype => 'DERIVE')
                  },
                  :thresholds => {
                  }
             },
             'ClosedConnectionRate' =>  { :description => 'Closed Connection Rate',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Per Second'},
                  :cmd => 'ClosedConnectionRate!:::node.workorder.rfcCi.ciAttributes.jmx_port:::',
                  :cmd_line => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:$OO_LOCAL{jmxPort}/jmxrmi -O kafka.rest:type=jetty-metrics -A connections-closed-rate',
                  :metrics =>  {
                    'connections-closed-rate'   => metric( :unit => 'per second', :description => 'Closed Connection Rate', :dstype => 'DERIVE')
                  },
                  :thresholds => {
                  }
             },
             'ThreadCount' =>  { :description => 'Thread Count',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Number'},
                  :cmd => 'ThreadCount!:::node.workorder.rfcCi.ciAttributes.jmx_port:::',
                  :cmd_line => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:$OO_LOCAL{jmxPort}/jmxrmi -O java.lang:type=Threading -A ThreadCount',
                  :metrics =>  {
                    'ThreadCount'   => metric( :unit => 'count', :description => 'Thread Count')
                  },
                  :thresholds => {
                  }
             },
             'MemoryUsage' =>  { :description => 'Memory Usage',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>'Number'},
                  :cmd => 'MemoryUsage!:::node.workorder.rfcCi.ciAttributes.jmx_port:::',
                  :cmd_line => '/opt/nagios/libexec/check_jmx -U service:jmx:rmi:///jndi/rmi://127.0.0.1:$OO_LOCAL{jmxPort}/jmxrmi -O java.lang:type=Memory -A HeapMemoryUsage -K used -I HeapMemoryUsage -J used -vvvv',
                  :metrics =>  {
                    'committed'   => metric( :unit => 'bytes', :description => 'Committed'),
                    'init'   => metric( :unit => 'bytes', :description => 'Initialized'),
                    'max'   => metric( :unit => 'bytes', :description => 'Initialized'),
                    'used'   => metric( :unit => 'bytes', :description => 'Initialized')
                  },
                  :thresholds => {
                  }
             }
         }


resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

}

resource "keystore",
  :cookbook => "oneops.1.keystore",
  :design => true,
  :requires => {"constraint" => "0..1"}

resource "client-certs-download",
   :cookbook => "oneops.1.download",
   :design => true,
   :requires => {
     :constraint => "0..*"
   },
   :attributes => {
     :source => '',
     :basic_auth_user => "",
     :basic_auth_password => "",
     :path => '',
     :post_download_exec_cmd => ''
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
 {:from => 'volume-kafkarest', :to => 'os'},
 {:from => 'user-kafkarest', :to => 'volume-kafkarest'},
 {:from => 'client-certs-download', :to => 'user-kafkarest'},
 {:from => 'kafka_rest', :to => 'volume-kafkarest'},
 {:from => 'java', :to => 'volume-kafkarest'  },
 {:from => 'kafka_rest', :to => 'user-kafkarest'  },
 {:from => 'kafka_rest', :to => 'certificate'  },
 {:from => 'kafka_rest', :to => 'keystore'  },
 {:from => 'keystore', :to => 'certificate'  },
 {:from => 'artifact',      :to => 'kafka_rest'},
 {:from => 'jolokia_proxy', :to => 'java'  },
 {:from => 'os', :to => 'compute'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# propagation rule for replace
[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

# managed_via
['user-kafkarest', 'artifact', 'kafka_rest', 'java', 'library', 'volume-kafkarest','keystore', 'client-certs-download','jolokia_proxy'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end