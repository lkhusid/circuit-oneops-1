name             "Memcached"
description      "Installs/configures memcached"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']


attribute 'port',
          :description => "Memcache Port",
          :default => "11211",
          :format => {
              :help => 'default port for Memcached',
              :category => '1.Global',
              :order => 1,
              :editable => false,
          }

attribute 'max_memory',
          :description => "Max memory allocated to Memcached",
          :default => "1024",
          :format => {
              :help => 'Max memory to use for items in megabytes',
              :category => '1.Global',
              :order => 2
          }

attribute 'max_connections',
          :description => "Maximum number of connections",
          :default => "1024",
          :format => {
              :help => 'Max simultaneous connections (default: 1024)',
              :category => '1.Global',
              :order => 3
          }

attribute 'log_file',
        :description => "Memcached log file path",
        :default => "/var/log/memcached.log",
        :format => {
            :help => 'Memcached log file path',
            :category => '1.Global',
            :order => 4
        }

attribute 'version',
          :description => "Memcached Version",
          :default => "repo",
          :format => {
              :help => 'Enter Memcached Version. Example: "1.4.39-1.el7" or "repo" for standard version from enabled repos',
              :category => '2.Advanced',
              :order => 1,
          }

attribute 'log_level',
        :description => "Memcached log level",
        :default => "disabled",
        :format => {
            :help => 'Memcached log level',
            :category => '2.Advanced',
            :order => 5,
            :form => {'field' => 'select', 'options_for_select' => [
                    ['Disabled', 'disabled'], ['Verbose', 'verbose'], ['Very Verbose', 'very_verbose'], ['Extremely Verbose', 'extremely_verbose']
                ]
            }
        }

attribute 'enable_cas',
        :description => "Enable cas command",
        :default => 'true',
        :format => {
            :help => 'Enable cas command',
            :category => '2.Advanced',
            :form => { 'field' => 'checkbox' },
            :order => 6
        }

attribute 'enable_error_on_memory_ex',
        :description => "Enable Error on Memory Exhaustion",
        :default => 'false',
        :format => {
            :help => 'Return error on memory exhausted (rather than removing items) ( -M )',
            :category => '2.Advanced',
            :form => { 'field' => 'checkbox' },
            :order => 7
        }

attribute 'num_threads',
        :description => "Number of Threads",
        :default => "4",
        :format => {
            :help => 'Number of threads to use (default: 4)',
            :category => '2.Advanced',
            :order => 8
        }

attribute 'additional_cli_opts',
        :description => "Additional CLI Options",
        :data_type => 'array',
        :default => '[]',
        :format => {
            :help => 'Additional CLI Options',
            :category => '3.Additional Options',
            :order => 9
        }

recipe "status", "Memcached Status"
recipe "start", "Start Memcached"
recipe "stop", "Stop Memcached"
recipe "restart", "Restart Memcached"
recipe "repair", "Repair Memcached"
