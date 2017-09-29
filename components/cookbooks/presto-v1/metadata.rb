name             'Presto-v1'
maintainer       'Walmart Labs'
maintainer_email 'paas@email.wal-mart.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures presto'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'
depends          'shared'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

# installation attributes

attribute 'version',
          :description => 'Version',
          :required => 'required',
          :default  => '0.152-SNAPSHOT',
          :format  => {
              :important  => true,
              :help  => 'Version of Presto',
              :category  => '1.Global',
              :order  => 1
          }

attribute 'http_port',
          :description => "HTTP port",
          :default => '8080',
          :format => {
              :help => 'HTTP port to use for internal communication',
              :category => '1.Global',
              :order => 2
          }

attribute 'enable_ssl',
          :description => "Enable SSL Communications",
          :default => 'true',
          :format => {
              :help => 'This will generate a keystore and truststore and enable ssl communication external to the cluster',
              :category => '1.Global',
              :order => 3,
              :form => {'field' => 'checkbox'}
          }

attribute 'https_port',
          :description => "HTTPS port",
          :default => '8443',
          :format => {
              :help => 'HTTPS port to use for external communication',
              :category => '1.Global',
              :order => 4
          }

attribute 'data_directory_dir',
          :description  => 'Data Directory',
          :default  => '/mnt/presto/data',
          :format  => {
              :help  => 'Location for metadata and temporary data',
              :category  => '1.Global',
              :order => 5
          }

attribute 'presto_rpm_install_url',
        :description  => 'Presto RPM Install URL',
        :default  => 'URL to rpm.  Use $version to for version identifer',
        :format  => {
            :help  => 'Presto RPM Install URL. $version will be replaceed with the version of presto',
            :category  => '1.Global',
            :order  => 6
        }

attribute 'presto_client_install_url',
        :description  => 'Presto Client Install URL',
        :default  => 'URL to jar.  Use $version to for version identifer',
        :format  => {
            :help  => 'Presto Client Install URL. $version will be replaceed with the version of presto',
            :category  => '1.Global',
            :order  => 7
        }


attribute 'jce_install_url',
        :description  => 'Java Cryptography Extensions URL',
        :default  => 'URL to zip file.',
        :format  => {
            :help  => 'Java Cryptography Extensions distribution URL. This file will be expanded into the Java directory.)',
            :category  => '1.Global',
            :order  => 8
        }

attribute 'query_max_memory',
          :description => 'Max Query Memory',
          :default => '260GB',
          :format => {
              :help => 'The maximum amount of distributed memory that a query may use.  Should be Max Query Memory Per Node * Node Count',
              :category => '1.Global',
              :order => 9
          }

attribute 'query_max_memory_per_node',
          :description => 'Max Query Memory Per Node',
          :default => '26GB',
          :format => {
              :help => 'The maximum amount of memory that a query may use on any one machine.  Should be about half of the Presto Heap Size',
              :category => '1.Global',
              :order => 10
          }

attribute 'ganglia_servers',
        :description => 'Ganglia Servers',
        :required => "required",
        :default => '127.0.0.1:8649',
        :format => {
            :help => 'Specify ganglia servers to point metrics to. Format HOST:PORT',
            :category => '1.Global',
            :order => 11
        }

attribute 'presto_ldap_server',
        :description => 'Presto LDAP Server',
        :required => true,
        :default => " ",
        :format => {
            :help => 'Specify the LDAP server to use for authentication. (Must support LDAPS.)',
            :category => '1.Global',
            :order => 12
        }

attribute 'presto_ldap_domain',
        :description => 'Presto LDAP Domain',
        :required => true,
        :default => " ",
        :format => {
            :help => 'Specify the LDAP authentication domain.',
            :category => '1.Global',
            :order => 13
        }

attribute 'jmx_mbeans',
        :description => 'JMX MBeans',
        :required => "required",
        :default => 'java.lang:type=Runtime,com.facebook.presto.execution.scheduler:name=NodeScheduler',
        :format => {
            :help => 'A comma separated list of Managed Beans (MBean). It specifies which MBeans will be sampled and stored in memory every',
            :category => '1.Global',
            :order => 14
        }

attribute 'jmx_dump_period',
        :description => 'JMX Dump Period',
        :required => "required",
        :default => '10s',
        :format => {
            :help => 'Interval that data is polled',
            :category => '1.Global',
            :order => 15
        }

attribute 'jmx_max_entries',
        :description => 'JMX Max Entries',
        :required => "required",
        :default => '86400',
        :format => {
            :help => 'The size of the history for the JMX entries',
            :category => '1.Global',
            :order => 16
        }

attribute 'log_level',
        :description => 'Presto Log Level',
        :required => "required",
        :default => 'INFO',
        :format => {
            :help => 'The log level for Presto.',
            :category => '1.Global',
            :order => 17,
            :form => {'field' => 'select', 'options_for_select' =>
                [['DEBUG', 'DEBUG'], ['INFO', 'INFO'],
                 ['WARN', 'WARN'], ['ERROR', 'ERROR']
                ]}
        }

attribute 'presto_mem',
        :description => 'Presto Heap Size',
        :required => "required",
        :default => '51G',
        :format => {
            :help => 'Heap size for Presto.  This is the Xmx setting for the JVM',
            :category => '1.Global',
            :order => 18
        }

attribute 'presto_thread_stack',
        :description => 'Presto Thread Stack Size',
        :required => "required",
        :default => '768k',
        :format => {
            :help => 'Thread stack size for Presto.  This is the Xss setting for the JVM',
            :category => '1.Global',
            :order => 19
        }

recipe 'status', 'Presto Status'
recipe 'start', 'Start Presto'
recipe 'stop', 'Stop Presto'
recipe 'restart', 'Restart Presto'
recipe 'repair', 'Repair Presto'
