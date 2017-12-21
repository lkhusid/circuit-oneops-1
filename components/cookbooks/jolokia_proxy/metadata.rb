name             'Jolokia_proxy'
maintainer       'Dpatil'
maintainer_email 'dpatil@walmartlabs.com'
license          'All rights reserved'
description      'Installs/Configures jolokia_proxy'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'


grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

# installation attributes


attribute 'enable_jolokia_proxy',
 :description => "Enable/Disable Jolokia Proxy",
 :default => "true",
 :format => {
     :category => '1.Configuration Parameters',
     :help => 'Enable or disable the Jolokia Proxy',
     :order => 1,
     :form => {'field' => 'checkbox'}
 }   
    
attribute 'version',
  :description          => 'Jetty Server Version',
  :required => "required",
  :default               => '9.3.10.v20160621',
  :format => {
    :important => true,
    :category => '1.Configuration Parameters',
    :help => 'Jetty Server version',
    :form => {'field' => 'select', 'options_for_select' => ['9.3.10.v20160621']},
    :order => 2
  } 

  
attribute 'jolokia_war_version',
  :description          => 'Jolokia Proxy Version',
  :required => "required",
  :default               => '1.3.3',
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Version of the Jolokia war file ',
    :form => {'field' => 'select', 'options_for_select' => ['1.3.3']},
    :order => 3
  }    


attribute 'bind_host',
  :description          => 'Host/address to bind to',
  :required => 'optional',
  :default               => "127.0.0.1",
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Connector host/address to bind to',
    :form => {'field' => 'select', 'options_for_select' => ['127.0.0.1', '0.0.0.0']},
    :order => 4
  }  
   
  
  
 attribute 'bind_port',
  :description          => 'Jolokia Proxy Port to listen on',
  :required => 'optional',
  :default               => "17330",
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Jolokia Proxy Port',
    :order => 5,
    :pattern => "[0-9]+"
  }  
  

attribute 'jvm_parameters',
  :description          => 'JVM Parameters',
  :required => 'optional',
  :default               => '-Xms128m -Xmx128m',
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Run Jolokia_proxy with this user',
    :order => 6
  }
  
attribute 'jolokia_proxy_process_user',
  :description          => 'Jolokia Proxy Process User',
  :required => 'required',
  :default               => 'app',
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Run Jolokia_proxy with this user',
    :order => 7
  }
  
 
attribute 'log_location',
  :description          => 'Jetty Log Directory',
  :required => 'required',
  :default               => "/var/log/jolokia_proxy",
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Jetty Server Log Location',
    :order => 8
  }
attribute 'log_level',
  :description          => 'Jetty Log Level',
  :required => 'optional',
  :default               => "INFO",
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Log level for Jetty Server logs',
    :form => {'field' => 'select', 'options_for_select' => ['INFO', 'DEBUG']},
    :order => 9
  }   


  
  
attribute 'jetty_log_max_filesize',
  :description          => 'Jetty Log Max File Size in MB',
  :required => 'optional',
  :default               => "10",
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Jetty Server Max File Size In MB',
    :order => 10
  } 
 
attribute 'jetty_log_backup_index',
  :description          => 'Number of Backup Log Files',
  :required => 'optional',
  :default               => "10",
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Jetty Server number of backup log files',
    :order => 11
  } 
 
  
attribute 'enable_requestlog_logging',
 :description => "Enable Request Log",
 :default => "false",
 :format => {
     :category => '1.Configuration Parameters',
     :help => 'This will control request log logging for the server.',
     :order => 12,
     :form => {'field' => 'checkbox'}
 } 

attribute 'request_log_location',
  :description          => 'Request Log Directory',
  :required => 'required',
  :default               => "/var/log/jolokia_proxy",
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Jetty Server Request Log Location',
    :order => 13
  }

attribute 'request_log_retaindays',
  :description          => 'Request Log Retention In Days ',
  :required => 'optional',
  :default               => "5",
  :format => {
    :category => '1.Configuration Parameters',
    :help => 'Jetty Server Request Log Retention in Days',
    :order => 14
  }   

 

recipe "status", "Jolokia_proxy Status"
recipe "start", "Start Jolokia_proxy"
recipe "stop", "Stop Jolokia_proxy"
recipe "restart", "Restart Jolokia_proxy"
recipe "repair", "Repair Jolokia_proxy"