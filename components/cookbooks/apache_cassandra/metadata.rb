name             "Apache_cassandra"
description      "Installs/Configures Cassandra"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Copyright OneOps, All rights reserved."

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest']

grouping 'bom',
         :access => "global",
         :packages => ['bom']


attribute 'version',
          :description => "Version",
          :required => "required",
          :default => "2.1.16",
          :format => {
              :important => true,
              :help => 'Cassandra version.  The latest 3.x version where x is odd is recommended.  2.0.x, 2.1.x and 3.x versions may be deployed (not 2.2.x). 2.0.x is not supported.',
              :category => '1.Global',
              :order => 1,
          }

attribute 'cluster',
          :description => "Cluster Name",
          :default => '',
          :format => {
              :help => 'Name of the cluster',
              :category => '1.Global',
              :order => 2
          }

attribute 'endpoint_snitch',
          :description => "Endpoint Snitch",
          :required => "required",
          :default => "GossipingPropertyFileSnitch",
          :format => {
              :important => true,
              :help => 'Sets the snitch to use for locating nodes and routing requests. Always use GossipingPropertyFileSnitch.',
              :category => '2.Topology',
              :order => 1,
              :editable => false
          }

attribute 'cloud_dc_rack_map',
          :description => "Map of Cloud to DC:Rack",
          :default => "{}",
          :required => "required",
          :data_type => "hash",
          :format => {
              :help => 'Map of Cloud to DC:Rack e.g cloud_name => dc_name:rack_name',
              :category => '2.Topology',
              :order => 2,
              :filter => {"all" => {"visible" => ('endpoint_snitch:eq:PropertyFileSnitch || endpoint_snitch:eq:GossipingPropertyFileSnitch')}}
          }

attribute 'node_ip',
          :description => "Node IP",
          :default => "",
          :grouping => "bom",
          :data_type => "text",
          :format => {
              :help => 'Node IP (used during replace)',
              :category => '2.Topology',
              :order => 3
          }

attribute 'node_version',
          :description => "Node Version",
          :default => "",
          :grouping => "bom",
          :data_type => "text",
          :format => {
          	  :important => true,
              :help => 'Node Version (used during upgrade)',
              :category => '2.Topology',
              :order => 4
          }

attribute 'config_directives',
          :description => 'Cassandra Options',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Overrides config/cassandra.yaml entries. Nested config values like list and mappings can be expressed as JSON (Eg: [],{} etc).  Eg: concurrent_writes = 64',
              :category => '3.Configuration Directives',
              :order => 1
          }

attribute 'log4j_directives',
          :description => 'Log4j Options',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Overrides config/log4j-server.properties entries. Eg: log4j.appender.R.maxFileSize = 20MB.  Only applies to versions prior to 2.0.',
              :category => '3.Configuration Directives',
              :order => 2
          }

attribute 'jvm_opts',
          :description => 'JVM Options',
          :required => "required",
          :default => '[]',
          :data_type => 'array',
          :format => {
              :help => 'Array of JVM_OPTS for cassandra-env.sh. Eg: -XX:SurvivorRatio=8',
              :category => '3.Configuration Directives',
              :order => 2
          }

attribute 'auth_enabled',
          :description => 'Enable authentication',
          :required => 'required',
          :default => 'false',
          :format => {
            :help => 'Enable authentication',
            :category => '3.Configuration Directives',
            :order => 3,
            :form => { 'field' => 'checkbox' }
#            :editable => false
          }

attribute 'username',
          :description => 'Username',
          :default => '',
          :format => {
            :help => 'Database super user name.  Update this only if you have changed the super user password or added a super user on the cluster manually.',
            :category => '3.Configuration Directives',
            :order => 4,
            :filter => {"all" => {"visible" => ('auth_enabled:eq:true')}}
          }

attribute 'password',
          :description => 'Password',
          :default => '',
          :encrypted => true,
          :format => {
            :help => 'Database super user password.  Update this only if you have changed the super user password or added a super user on the cluster manually.',
            :category => '3.Configuration Directives',
            :order => 5,
            :filter => {"all" => {"visible" => ('auth_enabled:eq:true')}}
          }

attribute 'checksum',
          :description => "Binary distribution checksum",
          :format => {
              :category => '5.Mirror',
              :help => 'md5 checksum of the file',
              :order => 1
          }

recipe "status", "Cassandra Status"
recipe "start", "Start Cassandra"
recipe "stop", "Stop Cassandra"
recipe "restart", "Restart Cassandra"
recipe "check_health", "Check Health for Cassandra"
recipe "upgradesstables", "UpgradeSSTables"
recipe "collect_diagnostic", "Collect Diagnostics"

recipe "customnodetool",
      :description => "Submit custom nodetool parameter",
      :args => {
        "CustomNodetoolArg" => {
        "name" => "CustomNodetoolArg",
        "description" => "CustomNodetoolArg",
        "defaultValue" => "",
        "required" => true,
        "dataType" => "string"
        }
      }
recipe "upgrade",
      :description  => "Upgrade SSTables as well after new version is installed. It's Data intensive. Warning: You can not rollback version if selected Yes.",
      :args => {
        "UpgradeSSTables" => {
        "name"        => "UpgradeSSTables",
        "description" => "Upgrade SSTables ?",
        "defaultValue"=> "yes",
        "required"    => true,
        "dataType"    => "string"
        }
      }
