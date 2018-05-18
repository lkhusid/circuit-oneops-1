name             "Enterprise_server"
description      "Installs/Configures Enterprise Server"
version          "1.0.0"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Copyright 2016, OneOps, All rights reserved."

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

# Installation attributes
attribute 'install_root_dir',
  :description => "Installation Root Directory",
  :required => "required",
  :default => "/opt",
  :format => {
      :category => '1.Global',
      :help => 'Installation root directory',
      :order => 1
  }

attribute 'install_version_major',
  :description => "Major Version",
  :required => "required",
  :default => "2",
  :format => {
      :category => '1.Global',
      :help => 'Major Version',
      :order => 2
  }

attribute 'install_version_minor',
  :description => "Minor version",
  :required => "required",
  :default => "2.0",
  :format => {
      :category => '1.Global',
      :help => 'Minor Version [1.2]',
      :order => 3
  }

# Runtime Attributes
attribute 'server_user',
  :description => "User",
  :default => 'tomee',
  :format => {
      :category => '1.Global',
      :help => 'Specify the userid that the Enterprise Server will run under.',
      :order => 4
  }

attribute 'server_group',
  :description => "Group",
  :default => 'tomee',
  :format => {
      :category => '1.Global',
      :help => 'Specify the groupid that the Enterprise Server will run under.',
      :order => 5
  }

attribute 'environment_settings',
          :description => "Environment Settings",
          :data_type => "hash",
          :default => "{}",
          :format => {
              :help => "Specify any environment settings that need to be placed in the .profile of the Enterprise Server User (ex: TZ=UTC).",
              :category => "1.Global",
              :order => 6
          }

attribute 'server_mgt_port',
  :description => "Server port",
  :required => "required",
  :default => "8005",
  :format => {
      :category => '1.Global',
      :help => 'Management Port',
      :order => 7
  }

attribute 'haveged_enabled',
  :description => "Install haveged",
  :default => "true",
  :format => {
      :category => '1.Global',
      :help => 'Install haveged to provide higher quality entropy for Linux based system (non-Debian)',
      :order => 8,
      :form => {'field' => 'checkbox'}
  }

  ##################################################################################################
  # Attributes for context.xml Configuration
  ##################################################################################################
  attribute 'override_context_enabled',
            :description => "Enable Override of context.xml File",
            :default => "false",
            :format => {
                :help => "Enable the replacement of the contents of the context.xml file.",
                :form => { "field" => "checkbox" },
                :category => "2.Context",
                :order => 1
            }

  attribute 'context_es',
            :description => "Replacement Configuration for context.xml",
            :default => IO.read(File.join(File.dirname(__FILE__), "files/context.xml")),
            :data_type => "text",
            :format => {
                :help => "Text in this field will override the existing context.xml file.",
                :filter => {"all" => {"visible" => "override_context_enabled:eq:true"}},
                :category => "2.Context",
                :order => 2
            }
#################################################################################################
# Attributes for server.xml Configuration
##################################################################################################
attribute 'override_server_enabled',
          :description => "Enable Override of server.xml File",
          :default => "false",
          :format => {
              :help => "Enable the replacement of the contents of the server.xml file.",
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 1
          }

attribute 'server_es',
          :description => "Additional Configuration for server.xml",
          :default => " ",
          :data_type => "text",
          :format => {
              :help => "Define the values that you want to override in the existing server.xml file.",
              :filter => {"all" => {"visible" => "override_server_enabled:eq:true"}},
              :category => "3.Server",
              :order => 2
          }

attribute 'http_nio_connector_enabled',
          :description => "Enable HTTP Connector",
          :default => "true",
          :format => {
                :help => "Enable the HTTP Connector (Non-SSL/TLS) Connector.",
                :filter => {"all" => {"visible" => "override_server_enabled:eq:false"}},
                :form => {"field" => "checkbox"},
                :category => "3.Server",
                :order => 3
            }

  attribute 'port',
            :description => "HTTP Port",
            :required => "required",
            :default => "8080",
            :format => {
                :help => "Specify the port that Enterprise Server will listen on for incoming HTTP (Non-SSL) requests",
                :filter => {"all" => {"visible" => ('override_server_enabled:eq:false && http_nio_connector_enabled:eq:true')}},
                :pattern => "[0-9]+",
                :category => "3.Server",
                :order => 4
            }
   attribute 'http_connector_protocol',
              :description => 'HTTP connector type',
              :default => 'org.apache.coyote.http11.Http11NioProtocol',
              :format => {
                  :category => '4.Server',
                  :help => 'HTTP Connector Type',
                  :order => 5,
                  :form => {'field' => 'select', 'options_for_select' => [
                      ['Blocking HTTP 1.1', 'org.apache.coyote.http11.Http11Protocol'],
                      ['Non Blocking HTTP 1.1', 'org.apache.coyote.http11.Http11NioProtocol'],
                      ['APR Native Connector', 'org.apache.coyote.http11.Http11AprProtocol']
                  ]}
              }

attribute 'https_nio_connector_enabled',
          :description => "Enable HTTPS Connector",
          :default => "false",
          :format => {
                :help => "Enable the HTTPS Connector (SSL/TLS) Connector.",
                :filter => {"all" => {"visible" => "override_server_enabled:eq:false"}},
                :form => {"field" => "checkbox"},
                :category => "3.Server",
                :order => 5
          }

attribute 'ssl_port',
          :description => "HTTPS Port",
          :required => "required",
          :default => "8443",
          :format => {
              :help => "Specify the port that Enterprise Server will listen on for incoming HTTPS (SSL) requests",
              :filter => {"all" => {"visible" => ('override_server_enabled:eq:false && https_nio_connector_enabled:eq:true')}},
              :pattern => "[0-9]+",
              :category => "3.Server",
              :order => 6
          }
    attribute 'https_connector_protocol',
            :description => 'SSL Connector Type',
            :default => 'org.apache.coyote.http11.Http11NioProtocol',
            :format => {
                :category => '3.Server',
                :help => 'SSL Connector Type',
                :order => 7,
                :form => {'field' => 'select', 'options_for_select' => [
                    ['Blocking HTTP 1.1', 'org.apache.coyote.http11.Http11Protocol'],
                    ['Non Blocking HTTP 1.1', 'org.apache.coyote.http11.Http11NioProtocol'],
                    ['APR Native Connector', 'org.apache.coyote.http11.Http11AprProtocol']
                ]}
            }
attribute 'max_threads',
          :description => 'Max Number of Threads',
          :required => 'required',
          :default => '50',
          :format => {
              :help => "Specify the max number of active threads in Enterprise Server's threadpool.",
              :filter => {"all" => {"visible" => ('override_server_enabled:eq:false && https_nio_connector_enabled:eq:true')}},
              :pattern => '[0-9]+',
              :category => "3.Server",
              :order => 8
          }

attribute 'advanced_security_options',
          :description => "Advanced Security Options",
          :default => "false",
          :format => {
              :help => "Display advanced security options (Note: Hiding the options does not disable or default any settings changed by the user.)",
              :filter => {"all" => {"visible" => ('override_server_enabled:eq:false && https_nio_connector_enabled:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 9
          }

attribute 'tlsv11_protocol_enabled',
          :description => "Enable TLSv1.1",
          :default => "false",
          :format => {
              :help => "If TLS is enabled by adding a certificate and keystore, this attribute determines if the TLSv1.1 protocol and ciphers are enabled.",
              :filter => {"all" => {"visible" => ('override_server_enabled:eq:false && https_nio_connector_enabled:eq:true && advanced_security_options:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 10
          }
attribute 'tlsv12_protocol_enabled',
          :description => "Enable TLSv1.2",
          :default => "true",
          :format => {
              :help => "If SSL/TLS is enabled by adding a certificate and keystore, this attribute determines if the TLSv1.2 protocol and ciphers are enabled.",
              :filter => {"all" => {"visible" => ('override_server_enabled:eq:false && https_nio_connector_enabled:eq:true && advanced_security_options:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 11
          }

attribute 'advanced_nio_connector_config',
          :default => '{"connectionTimeout":"20000","maxKeepAliveRequests":"100"}',
          :description => 'Additional Attributes for Enterprise Server Connector',
          :data_type => 'hash',
          :required => 'required',
          :format => {
                :help => 'These additional attributes (ex: attr_name1="value1" attr_name2="value2") will be appended to both HTTP and HTTPS connector elements in server.xml (enabled or not).',
                :filter => {"all" => {"visible" => "override_server_enabled:eq:false && (http_nio_connector_enabled:eq:true || https_nio_connector_enabled:eq:true)"}},
                :category => "3.Server",
                :order => 12
          }

attribute 'autodeploy_enabled',
                :description => "WAR File autoDeploy",
                :default => "false",
          :format => {
              :help => "Enable autoDeploy",
              :filter => {"all" => {"visible" => "override_server_enabled:eq:false"}},
              :form => {"field" => "checkbox"},
              :category => "3.Server",
              :order => 13
          }
attribute 'http_methods',
          :description => "Allow enablement of HTTP methods",
          :default => "false",
          :format => {
              :help => "Display HTTP methods (Note: Hiding the options does not disable or default any settings changed by the user.)",
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 14
          }

attribute 'enable_method_get',
          :description => "Enable GET HTTP method",
          :default => "true",
          :format => {
              :help => "Enable the GET HTTP method",
              :filter => {"all" => {"visible" => ('http_methods:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 15
          }

attribute 'enable_method_put',
          :description => "Enable PUT HTTP method",
          :default => "true",
          :format => {
              :help => "Enable the PUT HTTP method",
              :filter => {"all" => {"visible" => ('http_methods:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 16
          }

attribute 'enable_method_post',
          :description => "Enable POST HTTP method",
          :default => "true",
          :format => {
              :help => "Enable the POST HTTP method",
              :filter => {"all" => {"visible" => ('http_methods:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 17
          }

attribute 'enable_method_delete',
          :description => 'Enable DELETE HTTP method',
          :default => 'true',
          :format => {
              :help => "Enable the DELETE HTTP method",
              :filter => {"all" => {"visible" => ('http_methods:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 18
          }

attribute 'enable_method_options',
          :description => 'Enable OPTIONS HTTP method',
          :default => 'false',
          :format => {
              :help => "Enable the OPTIONS HTTP method",
              :filter => {"all" => {"visible" => ('http_methods:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 19
          }

attribute 'enable_method_head',
          :description => 'Enable HEAD HTTP method',
          :default => 'true',
          :format => {
              :help => "Enable the HEAD HTTP method",
              :filter => {"all" => {"visible" => ('http_methods:eq:true')}},
              :form => { "field" => "checkbox" },
              :category => "3.Server",
              :order => 20
          }
  attribute 'enable_method_trace',
            :description => 'Enable TRACE HTTP method',
            :default => 'false',
            :format => {
              :help => 'Disable / Enable the trace http method. Note: this applies to HTTP, HTTPS, and AJP Connectors',
              :category => '8.Advanced Connector Security Options',
              :filter => {'all' => {'visible' => 'advanced_connector_security_options:eq:true'}},
              :form => { 'field' => 'checkbox' },
              :order => 21
           }

##################################################################################################
# Attributes set in the setenv.sh script
##################################################################################################
attribute 'java_options',
          :description => "Java Options",
          :default => '-Djava.awt.headless=true',
          :format => {
              :help => 'Specify any JVM command line options needed in your Enterprise Server instance.',
              :category => '10.Java',
              :order => 1
          }

attribute 'system_properties',
          :description => "System Properties",
          :data_type => 'hash',
          :default => "{}",
          :format => {
              :important => true,
              :help => 'Specify any key value pairs for -D args to the jvm.',
              :category => '10.Java',
              :order => 2
          }

attribute 'startup_params',
          :description => "Startup Parameters",
          :data_type => 'array',
          :default => '["+UseConcMarkSweepGC", "+PrintGCDetails", "+PrintGCDateStamps", "-DisableExplicitGC", "+UseGCLogFileRotation", "NumberOfGCLogFiles=5", "GCLogFileSize=10M"]',
          :format => {
              :help => 'Specify any -XX arguments (without the -XX: in the values) needed.',
              :category => '10.Java',
              :order => 3
          }

attribute 'mem_max',
          :default => '512M',
          :description => "Max Heap Size",
          :format => {
              :important => true,
              :help => 'Set the Max Memory Heap Size for the Enterprise Server JVM.',
              :category => '10.Java',
              :order => 4
          }

attribute 'mem_start',
          :default => '256M',
          :description => 'Starting Heap Size',
          :format => {
              :help => 'Specify the starting Heap Size for the Enterprise Server JVM.',
              :category => '10.Java',
              :order => 5
          }


##################################################################################################
# Attributes to control log settings
##################################################################################################
attribute 'access_log_pattern',
          :default => '%h %l %u %t &quot;%r&quot; %s %b %D %F',
          :description => "Format of the Access Log",
          :format => {
              :help => 'Specify the format the access log data will be logged as.',
              :category => '3.Logs',
              :order => 1
          }

attribute 'server_log_path',
  :description => "Log Path",
  :required => "required",
  :default => "/log/enterprise-server",
  :format => {
      :category => '3.Logs',
      :help => 'Log Path Root',
      :order => 2
  }

attribute 'access_log_prefix',
  :description => "Log File prefix.",
  :default => 'access_log',
  :format => {
      :category => '3.Logs',
      :help => 'Log Prefix',
      :order => 3
}
attribute 'access_log_file_date_format',
  :description => "Date format to place in log file name.",
  :default => "yyyy-MM-dd",
  :format => {
      :category => '3.Logs',
      :help => 'Access Log Date Format',
      :order => 4
  }
  attribute 'access_log_suffix',
  :description => "The suffix to be  added to log file filenames.",
  :default => '.log',
  :format => {
      :category => '3.Logs',
      :help => 'Access Log Suffix',
      :order => 5
  }
attribute 'server_log_level',
    :description => "Log Level",
    :required => "required",
    :default => "WARNING",
    :format => {
        :category => '3.Logs',
        :help => 'Log Level',
        :form => {'field' => 'select', 'options_for_select' => [
            ['Severe (Highest Level)', 'SEVERE'],
            ['Warning', 'WARNING'],
            ['Info', 'INFO'],
            ['Config', 'CONFIG'],
            ['Fine', 'FINE'],
            ['Finer', 'FINER'],
            ['Finest (Lowest Level)', 'FINEST']]},
        :order => 6
    }


##################################################################################################
# Attributes for Enterprise Server instance startup and shutdown processes
##################################################################################################
attribute 'stop_time',
          :default => '45',
          :description => "Enterprise Server Shutdown Time Limit (secs)",
          :format => {
              :help => 'Specify the time limit to shutdown the Enterprise Server (seconds).',
              :pattern => "[0-9]+",
              :category => '7.Startup_Shutdown',
              :order => 1
          }

attribute 'pre_shutdown_command',
          :default => '',
          :description => 'Pre-Shutdown Command',
          :format => {
              :help => 'Specify the command to be executed before catalina stop is invoked. (Ex: It can be used to post request (using curl), which can trigger an ecv failure(response code 503). This will allow the load balancer to take the instance out of traffic.)',
              :category => '7.Startup_Shutdown',
              :order => 2
          }

attribute 'time_to_wait_before_shutdown',
          :default => '30',
          :description => 'Time (in seconds) Between Pre-Shutdown Command Execution and Enterprise Server Shutdown',
          :format => {
              :help=> "Specify the time (in seconds) to wait between the 'catalina stop' and the pre-shutdown commands executing.",
              :pattern => '[0-9]+',
              :category => '7.Startup_Shutdown',
              :order => 3
          }
attribute 'post_shutdown_command',
          :default => '',
          :description => 'Post-Shutdown Command',
          :data_type => 'text',
          :format => {
              :help => 'Specify the command to be executed after catalina stop is invoked.',
              :category => '7.Startup_Shutdown',
              :order => 4
          }

attribute 'pre_startup_command',
          :default => '',
          :description => 'Command to be executed before Enterprise Server has been started',
          :data_type => 'text',
          :format => {
              :help => "Specify the command to be executed before catalina start is invoked. The command should return a '0' for successful execution and a '1' for failure. (A returned '1' will cause the Enterprise Server startup to fail.)",
              :category => '7.Startup_Shutdown',
              :order => 5
          }

attribute 'post_startup_command',
          :default => '',
          :description => 'Command to be executed after Enterprise Server has been started',
          :data_type => 'text',
          :format => {
              :help => "Specify the command to be executed after catalina start is invoked. The command should return a '0' for successful execution and a '1' for failure. (A returned '1' will cause the Enterprise Server startup to fail.)",
              :category => '7.Startup_Shutdown',
              :order => 6
          }

attribute 'polling_frequency_post_startup_check',
          :default => '1',
          :description => 'Time (in seconds) between validation that Enterprise Server instance startup completed.',
          :format => {
              :help => "Specify how many seconds desired between status checks of Enterprise Server. If a post-startup command is specified, the command will run after Enterprise Server's status is validated as up.",
              :pattern => '[0-9]+',
              :category => '7.Startup_Shutdown',
              :order => 7
          }

attribute 'max_number_of_retries_for_post_startup_check',
          :default => '15',
          :description => 'Max number of retries validating Enterprise Server instance startup before post-startup command runs',
          :format => {
              :help => "Specify the number of times that verification the status of the Enterprise Server instance will be retried.",
              :pattern => '[0-9]+',
              :category => '7.Startup_Shutdown',
              :order => 8
          }


#Host Information
attribute 'host_unpack_wars',
  :description => "Unpack WAR Files",
  :default => 'false',
  :format => {
      :category => '8.Host',
      :help => 'Unpack WAR files or run from memory',
      :order => 1,
      :form => {'field' => 'checkbox'}
  }

attribute 'host_autodeploy',
  :description => 'Auto Deploy',
  :default => 'false',
  :format => {
      :category => '8.Host',
      :help => 'Auto deploys even on system change',
      :order => 2,
      :form => {'field' => 'checkbox'}
  }

attribute 'host_deploy_on_startup',
  :description => 'Deploy on Startup',
  :default => 'true',
  :format => {
      :category => '8.Host',
      :help => 'Deploys application on startup',
      :order => 3,
      :form => {'field' => 'checkbox'}
  }

attribute 'host_enable_error_report_valve',
  :description => 'Enable Error Report Valve',
  :default => 'true',
  :format => {
      :help => 'Disable / Enable the error report valve that hides data about the platform in default Enterprise Server generated error pages',
      :category => '8.Host',
      :form => { 'field' => 'checkbox' },
      :order => 4
  }

attribute 'host_enable_application_valve',
  :description => 'Enable Application Response Code Valve: only available at Enterprise Server v1.6.6 or later',
  :default => 'false',
  :format => {
      :help => 'Disable / Enable application response code valve',
      :category => '8.Host',
      :form => { 'field' => 'checkbox' },
      :order => 5
  }

attribute 'host_application_valve_collect_frequency',
  :description => 'Frequency of collection, runs once for the specified number of backgroundProcess calls (backgroundProcessDelay is specified by parent container element, default 10s)',
  :default => '6',
  :format => {
      :help => 'Only works when application valve is enabled, 60 seconds(6*10s=60s) by default',
      :category => '8.Host',
      :order => 6
  }

# JaaS Setting
attribute 'jaas_configuration_content',
  :description => "JaaS Configuration Content",
  :data_type => 'text',
  :default => '',
  :format => {
    :category => '10.JaaS Security Configuration',
    :help => 'JaaS Configuration Content',
    :order => 1
  }

# Enable Comet Filter
attribute 'comet_filter_enabled',
  :description => "Enable Comet Filter",
  :default => "false",
  :format => {
      :category => '10.Filters',
      :help => 'Enables the commet filter for andvanced I/O',
      :order => 1,
      :form => {'field' => 'checkbox'}
  }


##################################################################################################
# Included Recipes that you can run as an action from the Operations phase
##################################################################################################
recipe 'status', 'Enterprise Server Status'
recipe 'start', 'Start Enterprise Server'
recipe 'stop', 'Stop Enterprise Server'
recipe 'restart', 'Restart Enterprise Server'
recipe 'repair', 'Repair Enterprise Server'
recipe 'force-restart', 'Forces the stop of any Catalina process'
