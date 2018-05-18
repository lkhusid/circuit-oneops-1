name 'Cloudrdbms'
maintainer 'Cloud RDBMS Team'
maintainer_email 'GECCloudDB@email.wal-mart.com'
license 'none'
description 'Installs/Configures cloudrdbms'
#DO NOT DO THIS:  long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.0.0'

grouping 'default',
:access => 'global',
:packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'clustername',
  :description => 'Database Cluster Name',
  :required => 'required',
  :default => 'dbcluster',
  :format => {
    :help => 'Cloud RDBMS Team',
    :category => '1.Global',
    :order => 1
  }

attribute 'drclouds',
:description => 'DR Clouds',
:default => '',
:format => {
    :help => 'Comma-separated list of cloud names that you would like to be in the DR cluster',
    :category => '1.Global',
    :order => 1
}

attribute 'cloudrdbmspackversion',
:description => 'Cloud RDBMS Pack Version',
:required => 'required',
:default => '0',
:format => {
    :help => 'Cloud RDBMS Pack Version',
    :category => '1.Global',
    :order => 1,
    :editable => true
}

attribute 'managedserviceuser',
:description => 'Cloud RDBMS Managed Service User',
:required => 'required',
:default => 'svc_strati_ms',
:format => {
    :help => 'Cloud RDBMS Concord User',
    :category => '1.Global',
    :editable => true,
    :order => 1
}

attribute 'managedservicepass',
  :description => "Cloud RDBMS Managed Service Password",
  :required => "required",
  :encrypted => true,
  :default => "",
  :format => {
    :help => 'Concord password used for administration of the Cloud RDBMS pack',
    :category => '1.Global',
    :editable => true,
    :order => 1
}

attribute 'concordaddress',
:description => 'Cloud RDBMS Concord Address',
:required => 'required',
:default => 'server.ms.concord.devtools.prod.walmart.com:8001',
:format => {
    :help => 'Cloud RDBMS Concord Address',
    :category => '1.Global',
    :editable => true,
    :order => 1
}

recipe "status", "Status of the Cloud RDBMS"
recipe "start", "Start the Cloud RDBMS"
recipe "stop", "Stop the Cloud RDBMS"
recipe "restart", "Restart the Cloud RDBMS"
recipe "backup", 'Backup the database to objectstore'
#recipe "backup",
#:description => 'Backup the database to objectstore',
#:args => {
#  "backup_type" => {
#  "name" => "backup_type",
#  "description" => "backup type (full or incremental)",
#  "defaultValue" => "full",
#  "required" => true,
#  "dataType" => "string"
#  }
#}
recipe "list_backups", "list all available backups"
recipe "restore",
:description => 'Restore a backup from objectstore',
:args => {
  "organization" => {
  "name" => "organization",
  "description" => "organization",
  "defaultValue" => "",
  "required" => true,
  "dataType" => "string"
  },
  "assembly" => {
  "name" => "assembly",
  "description" => "assembly",
  "defaultValue" => "",
  "required" => true,
  "dataType" => "string"
  },
  "environment" => {
  "name" => "environment",
  "description" => "environment",
  "defaultValue" => "",
  "required" => true,
  "dataType" => "string"
  },
  "platform" => {
  "name" => "platform",
  "description" => "platform",
  "defaultValue" => "",
  "required" => true,
  "dataType" => "string"
  },
  "time" => {
  "name" => "time",
  "description" => "restore the database until time YYYY-MM-DD-HH24-MM-SS (e.g., 2016-04-13-21-00-00)",
  "defaultValue" => "",
  "required" => true,
  "dataType" => "string"
  }
}
