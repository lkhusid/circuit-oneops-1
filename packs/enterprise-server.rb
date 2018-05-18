include_pack  "genericlb"
name          "enterprise-server"
description   "Enterprise Server"
type          "Platform"
category      "Web Application"
version       "2"

environment "single", {}
environment "redundant", {}

platform :attributes => {'autoreplace' => 'false'}

variable "name",
         :description => 'Application name (app.name)',
         :value => ''

variable "domain",
         :description => 'Application domain (app.domain)',
         :value => ''

variable "groupId",
         :description => 'Group Identifier',
         :value => ''

variable "artifactId",
         :description => 'Artifact Identifier',
         :value => ''

variable "appVersion",
         :description => 'Artifact version',
         :value => ''

variable "extension",
         :description => 'Artifact extension',
         :value => 'war'

variable "repository",
         :description => 'Repository name',
         :value => ''

##SHA version of the artifact
variable "shaVersion",
         :description => 'CheckSum for artifact download',
         :value => ''

#The deployment context which application teams can set
variable "deployContext",
         :description => 'The context in which the app needs to be deployed',
         :value => ''

variable "runOnEnv",
         :description => 'Environment run configuration',
         :value => ''

#Enabling default http,https,ajp
resource 'secgroup',
         :cookbook   => 'oneops.1.secgroup',
         :design     => true,
         :attributes => {
             :inbound => '["22 22 tcp 0.0.0.0/0", "8080 8080 tcp 0.0.0.0/0","8443 8443 tcp 0.0.0.0/0","8009 8009 tcp 0.0.0.0/0","5701 5701 tcp 0.0.0.0/0"]'
         },
         :requires   => {
             :constraint => '1..1',
             :services   => 'compute'
         }

resource "keystore",
         :cookbook => "oneops.1.keystore",
         :design => true,
         :requires => {"constraint" => "0..1"},
         :attributes => {
             "keystore_filename" => "/opt/certs/keystore.jks"
         }

resource "user-app",
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

resource "rapidssl-keystore",
         :cookbook => "oneops.1.download",
         :design => true,
         :requires => {
             :constraint => "0..1",
         },
         :attributes => {
             :source =>"",
             :basic_auth_user => "",
             :basic_auth_password => "",
             :path => '/opt/.certs/rapidssl.jks',
             :post_download_exec_cmd => 'chown -R tomee:tomee /opt/.certs/'
         }

resource "enterprise_server",
         :cookbook => "oneops.1.enterprise_server",
         :design => true,
         :requires => {"constraint" => "1..1", :services => "mirror"},
         :attributes => {
             'install_root_dir' => '/opt',
             'install_version_major' => '2',
             'install_version_minor' => '6.1',
             'server_user' => 'tomee',
             'server_group' => 'tomee',
             'java_jvm_args' => '-Xms64mXmx1024m',
             'java_startup_params' => '[
                    "+UseCompressedOops",
                    "SurvivorRatio=10",
                    "SoftRefLRUPolicyMSPerMB=125"
                  ]',
             'access_log_dir' =>'/log/enterprise-server',
             'access_log_pattern'=>'%h %{NSC-Client-IP}i %l %u %t &quot;%r&quot; %s %b %D %F'
         },
	 :monitors => {
             'JvmInfo' => {:description => 'JvmInfo',
                           :source => '',
                           :chart => {'min' => 0, 'unit' => ''},
                           :cmd => 'check_tomcat_jvm',
                           :cmd_line => '/opt/nagios/libexec/check_tomcat.rb JvmInfo',
                           :metrics => {
                               'max' => metric(:unit => 'B', :description => 'Max Allowed', :dstype => 'GAUGE'),
                               'free' => metric(:unit => 'B', :description => 'Free', :dstype => 'GAUGE'),
                               'total' => metric(:unit => 'B', :description => 'Allocated', :dstype => 'GAUGE'),
                               'percentUsed' => metric(:unit => 'Percent', :description => 'Percent Memory Used', :dstype => 'GAUGE'),
                           },
                           :thresholds => {
                              'HighMemUse' => threshold('1m','avg', 'percentUsed',trigger('>=',90,5,1),reset('<',85,5,1)),
                           }
             },
             'ThreadInfo' => {:description => 'ThreadInfo',
                              :source => '',
                              :chart => {'min' => 0, 'unit' => ''},
                              :cmd => 'check_tomcat_thread',
                              :cmd_line => '/opt/nagios/libexec/check_tomcat.rb ThreadInfo',
                              :metrics => {
                                  'currentThreadsBusy' => metric(:unit => '', :description => 'Busy Threads', :dstype => 'GAUGE'),
                                  'maxThreads' => metric(:unit => '', :description => 'Maximum Threads', :dstype => 'GAUGE'),
                                  'currentThreadCount' => metric(:unit => '', :description => 'Ready Threads', :dstype => 'GAUGE'),
                                  'percentBusy' => metric(:unit => 'Percent', :description => 'Percent Busy Threads', :dstype => 'GAUGE'),
                              },
                              :thresholds => {
                                 'HighThreadUse' => threshold('5m','avg','percentBusy',trigger('>=',90,5,1),reset('<',85,5,1)),
                              }
             },
             'RequestInfo' => {:description => 'RequestInfo',
                               :source => '',
                               :chart => {'min' => 0, 'unit' => ''},
                               :cmd => 'check_tomcat_request',
                               :cmd_line => '/opt/nagios/libexec/check_tomcat.rb RequestInfo',
                               :metrics => {
                                   'bytesSent' => metric(:unit => 'B/sec', :description => 'Traffic Out /sec', :dstype => 'DERIVE'),
                                   'bytesReceived' => metric(:unit => 'B/sec', :description => 'Traffic In /sec', :dstype => 'DERIVE'),
                                   'requestCount' => metric(:unit => 'reqs /sec', :description => 'Requests /sec', :dstype => 'DERIVE'),
                                   'errorCount' => metric(:unit => 'errors /sec', :description => 'Errors /sec', :dstype => 'DERIVE'),
                                   'maxTime' => metric(:unit => 'ms', :description => 'Max Time', :dstype => 'GAUGE'),
                                   'processingTime' => metric(:unit => 'ms', :description => 'Processing Time /sec', :dstype => 'DERIVE')
                               },
                               :thresholds => {
                               }
             },
             'Log' => {:description => 'Log',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_logfiles!logtomcat!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                       :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                       :cmd_options => {
                           'logfile' => '/log/enterprise-server/catalina.out',
                           'warningpattern' => 'WARNING',
                           'criticalpattern' => 'CRITICAL'
                       },
                       :metrics => {
                           'logtomcat_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                           'logtomcat_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                           'logtomcat_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                           'logtomcat_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                       },
                       :thresholds => {
                         'CriticalLogException' => threshold('15m', 'avg', 'logtomcat_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1)),
                       }
             },
            'ResponseCodeInfo' => {:description => 'ResponseCodeInfo',
                              :source => '',
                              :chart => {'min' => 0, 'unit' => ''},
                              :cmd => 'check_es_response',
                              :cmd_line => '/opt/nagios/libexec/check_es_response.rb /log/enterprise-server/response_log.txt',
                              :metrics => {
                                  'rc200' => metric(:unit => 'min', :description => 'Response code 200', :dstype => 'GAUGE'),
                                  'rc304' => metric(:unit => 'min', :description => 'Response code 304', :dstype => 'GAUGE'),
                                  'rc404' => metric(:unit => 'min', :description => 'Response code 404', :dstype => 'GAUGE'),
                                  'rc500' => metric(:unit => 'min', :description => 'Response code 500', :dstype => 'GAUGE'),
                                  'rc2xx' => metric(:unit => 'min', :description => 'Response code family 2xx', :dstype => 'GAUGE'),
                                  'rc3xx' => metric(:unit => 'min', :description => 'Response code family 3xx', :dstype => 'GAUGE'),
                                  'rc4xx' => metric(:unit => 'min', :description => 'Response code family 4xx', :dstype => 'GAUGE'),
                                  'rc5xx' => metric(:unit => 'min', :description => 'Response code family 5xx', :dstype => 'GAUGE')
                              },
                              :thresholds => {
                              }
            }
         }

resource "artifact-app",
         :cookbook => "oneops.1.artifact",
         :design => true,
         :requires => {
             :constraint => "1..*",
             :services => "maven",
             :help => "Strati service configuration. You can use this form to customize the configuration parameters for your service."
         },
         :attributes => {
             :url => '',
             :repository => '$OO_LOCAL{repository}',
             :username => '',
             :password => '',
             :location => '$OO_LOCAL{groupId}:$OO_LOCAL{artifactId}:$OO_LOCAL{extension}',
             :version => '$OO_LOCAL{appVersion}',
             :checksum => '$OO_LOCAL{shaVersion}',
             :install_dir => '/opt/$OO_LOCAL{artifactId}',
             :as_user => 'tomee',
             :as_group => 'tomee',
             :environment => '{}',
             :persist => '[]',
             :should_expand => 'true',
             :configure => "directory \"/log/enterprise-server\" do \n  owner \'tomee\' \n  group \'tomee\' \n  not_if { File.exists?(\"/log/enterprise-server\") } \n  action :create \nend \n\n directory \"/log/logmon\" do \n  owner \'tomee\' \n  group \'tomee\' \n  action :create \nend",
             :migrate => '',
             :restart => "execute \"rm -fr /opt/enterprise-server/webapps/$OO_LOCAL{deployContext}\" \n\nlink \"/opt/enterprise-server/webapps/$OO_LOCAL{deployContext}\" do \n  to \"/opt/$OO_LOCAL{artifactId}/current\" \nend \n\nservice \"enterprise-server\" do \n  action :restart \nend\n\n"
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
                         'size' => metric(:unit => 'B', :description => 'Content Size', :dstype => 'GAUGE', :display => false),
                          'up' => metric(:unit => '', :description => 'Status', :dstype => 'GAUGE')

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
             },

             'logmon_artifact' => {:description => 'logmon_artifact',
                       :source => '',
                       :chart => {'min' => 0, 'unit' => ''},
                       :cmd => 'check_logmon_artifact!:::node.workorder.rfcCi.ciAttributes.install_dir:::',
                       :cmd_line => '/opt/nagios/libexec/check_logmon_artifact.sh $ARG1$',
                       :metrics => {
                           'errors' => metric(:unit => '/min', :description => 'errors', :dstype => 'GAUGE'),
                           'latency' => metric(:unit => 'ms', :description => 'latency', :dstype => 'GAUGE'),
                           'hits' => metric(:unit => '/min', :description => 'hits', :dstype => 'GAUGE')
                       },
                       :thresholds => {
                      }
             }

         }
resource "os",
           :cookbook => 'oneops.1.os',
           :design => true,
           :attributes => {
             :ostype => 'centos-7.3'
         }

resource "java",
           :cookbook => "oneops.1.java",
           :design => true,
           :requires => {
             :constraint => "1..1",
             :services => "mirror",
             :help => "java programming language environment"
           },
           :attributes => {

           }

resource "es_daemon",
      :cookbook => "oneops.1.daemon",
      :design => true,
      :requires => {
          :constraint => "1..1",
          :help => "Restarts Enterprise Server"
      },
      :attributes => {
          :service_name => 'enterprise-server',
          :use_script_status => 'true',
          :pattern => 'enterprise-server'
      },
      :monitors => {
          'enterpriseserverprocess' => {:description => 'EnterpriseServerProcess',
                        :source => '',
                        :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                        :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!:::node.workorder.rfcCi.ciAttributes.use_script_status:::!:::node.workorder.rfcCi.ciAttributes.pattern:::!:::node.workorder.rfcCi.ciAttributes.secondary_down:::',
                        :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                        :metrics => {
                            'up' => metric(:unit => '%', :description => 'Percent Up'),
                        },
                        :thresholds => {
                            'TomcatDaemonProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
                        }
          }
       }

resource "volume-log",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "compute"},
         :attributes => {"mount_point" => '/log',
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
                          'LowDiskSpaceCritical' => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                          'LowDiskInodeCritical' => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                      },
             },
         }

resource "volume-app",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "compute"},
         :attributes => {"mount_point" => '/app',
                         "size" => '10G',
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
                              'LowDiskSpaceCritical' => threshold('1m', 'avg', 'space_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                              'LowDiskInodeCritical' => threshold('1m', 'avg', 'inode_used', trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                            },
             }
         }

resource "share",
  :cookbook => "oneops.1.glusterfs",
  :design => true,
  :requires => {
    :constraint => "0..1",
    :services => "mirror"
    },
  :attributes => {
                    "store"   => '/log/share',
                    "volopts" => '{}',
                    "replicas" => "1",
                    "mount_point" => '/share'
                 }

resource "telegraf",
 :cookbook => "oneops.1.telegraf",
 :design => true,
 :requires => {
      "constraint" => "0..10",
      :services => "mirror"
 },
 :monitors => {
   'telegrafprocess' => {:description => 'TelegrafProcess',
     :source => '',
     :enable => 'true',
     :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
     :cmd => 'check_process_count!telegraf',
     :cmd_line => '/opt/nagios/libexec/check_process_count.sh "$ARG1$"',
     :metrics => {
           'count' => metric(:unit => '', :description => 'Running Process'),
     },
     :thresholds => {
           'TelegrafProcessLow' => threshold('1m', 'avg', 'count', trigger('<', 1, 1, 1), reset('>=', 1, 1, 1)),
           'TelegrafProcessHigh' => threshold('1m', 'avg', 'count', trigger('>=', 200, 1, 1), reset('<', 200, 1, 1))
     }
   }
 }

resource "filebeat",
 :cookbook => "oneops.1.filebeat",
 :design => true,
 :requires => {
      "constraint" => "0..10",
      :services => "mirror"
 },
 :monitors => {
   'filebeatprocess' => {:description => 'FilebeatProcess',
     :source => '',
     :enable => 'true',
     :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
     :cmd => 'check_process_count!filebeat',
     :cmd_line => '/opt/nagios/libexec/check_process_count.sh "$ARG1$"',
     :metrics => {
           'count' => metric(:unit => '', :description => 'Running Process'),
     },
     :thresholds => {
           'FilebeatProcessLow' => threshold('1m', 'avg', 'count', trigger('<', 1, 1, 1), reset('>=', 1, 1, 1)),
           'FilebeatProcessHigh' => threshold('1m', 'avg', 'count', trigger('>=', 200, 1, 1), reset('<', 200, 1, 1))
     }
   }
 }

resource "sensuclient",
         :cookbook => "oneops.1.sensuclient",
         :design => true,
         :requires => {"constraint" => "0..1"}

resource "ramdisk",
 :cookbook => "oneops.1.volume",
 :design => true,
 :requires => { "constraint" => "0..*", "services" => "compute" },
 :attributes => {  "mount_point"   => '',
                   "device"        => 'tmpfs',
                   "fstype"        => 'tmpfs',
                   "options"       => '',
                   "size"          => '512M'
                },
 :monitors => {
     'usage' =>  {'description' => 'Usage',
                 'chart' => {'min'=>0,'unit'=> 'Percent used'},
                 'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                 'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                 'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                                'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
                 :thresholds => {
                   'LowDiskSpaceCritical' => threshold('1m', 'avg', 'space_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1)),
                   'LowDiskInodeCritical' => threshold('1m', 'avg', 'inode_used',trigger('>=', 90, 5, 2), reset('<', 85, 5, 1))
                 },
               }
}

resource "batch-job",
  :cookbook => "oneops.1.job",
  :design => true,
  :requires => {
    :constraint => "0..1",
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
[{:from => 'artifact-app', :to => 'share'},
  {:from => 'share', :to => 'volume-log'},
  {:from => 'volume-log', :to => 'os'},
  {:from => 'volume-app', :to => 'os'},
  {:from => 'user-app', :to => 'volume-app'},
  {:from => 'java', :to => 'os'},
  {:from => 'enterprise_server', :to => 'os'},
  {:from => 'telegraf', :to => 'os'},
  {:from => 'filebeat', :to => 'os'},
  {:from => 'sensuclient', :to => 'os' },
  {:from => 'ramdisk', :to => 'os'},
  {:from => 'keystore', :to => 'java'},
  {:from => 'enterprise_server', :to => 'keystore'},
  {:from => 'rapidssl-keystore', :to => 'user-app'},
  {:from => 'enterprise_server', :to => 'user-app'},
  {:from => 'enterprise_server', :to => 'java'},
  {:from => 'artifact-app', :to => 'enterprise_server'},
  {:from => 'artifact-app', :to => 'library'},
  {:from => 'volume-log', :to => 'volume-app'},
  {:from => 'artifact-app', :to => 'volume-log'},
  {:from => 'artifact-app', :to => 'volume-app'},
  {:from => 'jolokia_proxy', :to => 'os'},
  {:from => 'jolokia_proxy', :to => 'java'},
  {:from => 'batch-job', :to => 'os'},
  {:from => 'batch-job', :to => 'java'},
  {:from => 'batch-job', :to => 'volume'},
  {:from => 'batch-job', :to => 'file'  },
  {:from => 'batch-job', :to => 'download'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

relation "es_daemon::depends_on::artifact-app",
	           :relation_name => 'DependsOn',
		              :from_resource => 'es_daemon',
			                 :to_resource => 'artifact-app',
					            :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

relation "es_daemon::depends_on::enterprise_server",
                   :relation_name => 'DependsOn',
                              :from_resource => 'es_daemon',
                                         :to_resource => 'enterprise_server',
                                                    :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

relation "artifact-app::depends_on::enterprise_server",
                   :relation_name => 'DependsOn',
                              :from_resource => 'artifact-app',
                                         :to_resource => 'enterprise_server',
                                                    :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

relation "es_daemon::depends_on::keystore",
	           :relation_name => 'DependsOn',
		              :from_resource => 'es_daemon',
			                 :to_resource => 'keystore',
					            :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

relation "keystore::depends_on::certificate",
	           :relation_name => 'DependsOn',
		              :from_resource => 'keystore',
			                 :to_resource => 'certificate',
					            :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}


# managed_via
['jolokia_proxy','batch-job','ramdisk','sensuclient','filebeat','telegraf','share','user-app', 'enterprise_server', 'artifact-app', 'java', 'library', 'volume-log', 'volume-app', 'keystore', 'es_daemon', 'rapidssl-keystore'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end

#simplified procedure for start and stop

[
    {:name => 'stop-all-one-by-one', :strategy => 'one-by-one', :description => 'Stop Web Application on all nodes one-by-one', :action => 'stop'},
    {:name => 'stop-all-in-parallel', :strategy => 'parallel', :description => 'Stop Web Application on all nodes in parallel', :action => 'stop'},
    {:name => 'start-all-one-by-one', :strategy => 'one-by-one', :description => 'Start Web Application on all nodes one-by-one', :action => 'start'},
    {:name => 'start-all-in-parallel', :strategy => 'parallel', :description => 'Start Web Application on all nodes in parralel', :action => 'start'},
    {:name => 'restart-all-one-by-one', :strategy => 'one-by-one', :description => 'ReStart Web Application on all nodes one by one', :action => 'restart'},
    {:name => 'restart-all-in-parallel', :strategy => 'parallel', :description => 'Restart Web Application on all nodes in parallel', :action => 'restart'},
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
    "targetClassName": "manifest.oneops.1.Enterprise_server",
    "flow": [
    {
        "relationName": "base.RealizedAs",
        "execStrategy": "'+link[:strategy]+'",
        "direction": "from",
        "targetClassName": "bom.oneops.1.Enterprise_server",
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
