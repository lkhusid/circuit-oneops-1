name                'Service-mesh'
description         'Installs/Configures service mesh process'
version             '1.0'
maintainer          'SOA'
maintainer_email    'cirrus@email.wal-mart.com'
license             'Apache License, Version 2.0'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'tenants',
  :description => "Tenants",
  :required => 'required',
  :data_type => "array",
  :default => "[\" \"]",
  :format => {
    :important => true,
    :category => '1.Application Config',
    :order => 1,
    :help => 'Enter tenant config as 4 values separated by space (application-key environment-name ingress-address ECV-url).E.g. "cart-app prod http://localhost:8086 /ecv.html"'
  }

attribute 'show-advanced-config',
          :description => 'Show advanced configuration',
          :required => 'optional',
          :default => 'false',
          :format      => {
            :help     => 'Select checkbox to see advanced configuration. Not recommended if you are not familiar with the configs',
            :category => '2.Advanced',
            :form     => {'field' => 'checkbox'},
            :order    => 1
          }

attribute 'service-mesh-version',
          :description => 'Service Mesh Version',
          :required => 'required',
          :default => '1.7.1',
          :format => {
              :important => true,
              :help => 'Service mesh version, do not change if not sure what value to use',
              :category => '2.Advanced',
              :filter   => {'all' => {'visible' => 'show-advanced-config:eq:true'}},
              :order => 4
          }

attribute 'service-mesh-root',
          :description => 'Service Mesh Root Directory',
          :required => 'required',
          :default => '/opt/service-mesh',
          :format => {
              :important => false,
              :help => 'Root directory for service-mesh component',
              :category => '2.Advanced',
              :filter   => {'all' => {'visible' => 'show-advanced-config:eq:true'}},
              :order => 5
          }

attribute 'conf-override',
          :description => 'Additional JVM Parameters',
          :required => 'optional',
          :default => '',
          :format => {
              :important => false,
              :help => 'Additional java vm parameter config to be applied to soa linkerd process',
              :category => '2.Advanced',
              :filter   => {'all' => {'visible' => 'show-advanced-config:eq:true'}},
              :order => 6
          }

attribute 'use-overridden-yaml',
          :description => 'Override config YAML?',
          :required => 'optional',
          :default => 'false',
          :format      => {
            :help     => 'Select checkbox to see advanced configuration. Not recommended if you are not familiar with the configs',
            :category => '2.Advanced',
            :form     => {'field' => 'checkbox'},
            :filter   => {'all' => {'visible' => 'show-advanced-config:eq:true'}},
            :order    => 7
          }

attribute 'config-yaml',
		  :description => "Complete Config YAML",
		  :data_type => "text",
		  :format => {
		    :help => 'Complete config in yaml format, this will override any other config',
		    :category => '2.Advanced',
		    :filter   => {'all' => {'visible' => 'show-advanced-config:eq:true && use-overridden-yaml:eq:true'}},
		    :order => 8
  		  }

recipe "restart-service-mesh-process", "Restart Service Mesh"
