name             "Filebeat"
description      "filebeat"
version          "0.1"
maintainer       "OneOps"
maintainer_email "kho@walmartlabs.com"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


# installation attributes
attribute 'version',
  :description          => 'Filebeat version',
  :required => "required",
  :default               => '1.3.1',
  :format => {
    :important => true,
    :category => 'Global',
    :help => 'Version of Filebeat',
    :order => 1,
    :form => {'field' => 'select', 'options_for_select' => [['v1.2.3', '1.2.3'],['v1.3.1', '1.3.1'],['v5.0.0', '5.0.0']]}
  }


attribute 'enable_agent',
  :description => "Enable agent",
  :default => "false",
  :format => {
      :category => 'Global',
      :help => 'This will control whether the filebeat agent should be running.',
      :order => 2,
      :form => {'field' => 'checkbox'}
  }

attribute 'enable_test',
  :description => "Enable Test",
  :default => "false",
  :format => {
      :category => 'Global',
      :help => 'If enabled, then during add/update, [filebeat  -configtest] must be run to validate the configuration..',
      :order => 3,
      :form => {'field' => 'checkbox'}
  }

attribute 'run_as_root',
  :description => "Run As Root",
  :default => "false",
  :format => {
      :category => 'Global',
      :help => 'Run Filebeat process as Root',
      :order => 4,
      :form => {'field' => 'checkbox'}
  }


attribute 'configdir',
  :description => "Configuration File Directory",
  :required => 'required',
  :default => '/etc/filebeat',
  :format => {
    :help => 'Configuration file Directory',
    :category => 'Global',
    :order => 5
  }


attribute 'configure',
  :description => "Configuration file Contents",
  :data_type => "text",
  :format => {
    :help => 'Resources to be executed to configure the filebeat package.',
    :category => 'Global',
    :order => 6
  }


recipe "start", "Start Filebeat"
recipe "stop", "Stop Filebeat"
recipe "restart", "Retart Filebeat"
recipe "status", "Filebeat Status"


