name                'Baas-job'
description         'Installs/Configures service mesh process'
version             '1.0'
maintainer          'BaaS'
maintainer_email    'gecbaas@email.wal-mart.com'
license             'Apache License, Version 2.0'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'job-type-1',
  :description => 'Job Type',
  :default => "Script",
  :required => "required",
  :format => {
    :help => "Job Type (Script, EJar etc)",
    :category => '1.Job Type 1',
    :form => {'field' => 'select', 'options_for_select' => [['Script', 'Script'], ['Executable Jar', 'EJar']]},
    :order => 1
  }
  
attribute 'job_map_1',
  :description => "Jobs",
  :required => "required",
  :default => '{"add-job-id":"add-job-artifact-path"}',
  :data_type => "hash",
  :format => {
    :important => true,
    :help => 'Provide Job-Id and job artifact',
    :category => '1.Job Type 1',
    :order => 2
  }
  
attribute 'job-type-2',
  :description => 'Job Type',
  :default => "EJar",
  :required => "required",
  :format => {
    :help => "Job Type (Script, EJar etc)",
    :category => '2.Job Type 2',
    :form => {'field' => 'select', 'options_for_select' => [['Script', 'Script'], ['Executable Jar', 'EJar']]},
    :order => 1
  }
  
attribute 'job_map_2',
  :description => "Jobs",
  :required => "required",
  :default => '{"add-job-id":"add-job-artifact-path"}',
  :data_type => "hash",
  :format => {
    :important => true,
    :help => 'Provide Job-Id and job artifact',
    :category => '2.Job Type 2',
    :order => 2
  }
  
attribute 'driver-id',
  :description => 'Driver ID',
  :default => "driver-id",
  :required => "required",
  :format => {
    :help => 'Provide driver ID for the runnable on baas portal',
    :category => '3.BaaS Configuration',
    :order => 1
  }

attribute 'show-advanced-config',
  :description => 'Override advanced configuration',
  :required => 'optional',
  :default => 'false',
  :format      => {
    :help     => 'Select checkbox to see advanced configuration. Not recommended if you are not familiar with the configs',
    :category => '3.BaaS Configuration',
    :form     => {'field' => 'checkbox'},
    :order    => 2
  }

attribute 'run-env',
  :description => 'runOnEnv',
  :default => "stg0",
  :required => "optional",
  :format => {
    :help => "Environment name (prod or stg0)",
    :category => '3.BaaS Configuration',
    :filter   => {'all' => {'visible' => 'show-advanced-config:eq:true'}},
    :order => 3
  }

attribute 'driver-version',
  :description => 'BaaS driver version',
  :default => "4.67.4",
  :required => "optional",
  :format => {
    :help => 'Version for BaaS driver app',
    :category => '3.BaaS Configuration',
    :filter   => {'all' => {'visible' => 'show-advanced-config:eq:true'}},
    :order => 4
  }

recipe "status", "Driver Status"
recipe "update", "Update driver"
recipe "stop", "Stop driver"
recipe "restart", "Restart driver"

