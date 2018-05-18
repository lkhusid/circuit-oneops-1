name             'Kafka_rest'
maintainer       'Platform Messaging'
maintainer_email 'GECMSGDE54@email.wal-mart.com'
license          'Copyright Walmart Technology, All rights reserved.'
description      'Installs and Configures Kafka Rest Proxy'
version          '0.1.1'

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

#Installation Attributes

attribute 'version',
  :description => 'Kafka Rest Proxy Version',
  :required => "required",
  :default => '3.2.0',
  :format => {
    :important => true,
    :category => '1.Global',
    :help => 'Version of Kafka Rest Proxy',
    :order => 1,
    :form => {'field' => 'select', 'options_for_select' => [['3.2.0', '3.2.0']]}
  }
  
attribute 'zookeeper_connect_url',
   :description => 'Zookeeper Connection string',
   :required => 'required',
   :default => '$OO_LOCAL{zkconnecturl}',
   :format => {
     :category => '1.Global',
     :help => 'List all the zookeeper (server:port) connections, for example: "hostname:port,hostname:port"',
     :order => 2
   }
   
attribute 'bootstrap_url',
   :description => 'Kafka Connect string',
   :required => 'required',
   :default => '$OO_LOCAL{kafkaconnecturl}',
   :format => {
     :category => '1.Global',
     :help => 'List all the kafka broker (server:port) connections, for example: "hostname:port,hostname:port"',
     :order => 3
   }
   
attribute 'listener',
   :description => 'REST Proxy listener',
   :required => 'required',
   :default  => 'http://0.0.0.0:$OO_LOCAL{port}',
   :format => {
     :category => '1.Global',
     :help => 'It is comma-separated list of listeners that listen for API requests over either HTTP or HTTPS',
     :order => 4
   }   

attribute 'log_dir',
   :description => 'log directory',
   :required => 'required',
   :default  => '/var/log/kafka-rest',
   :format => {
     :category => '1.Global',
     :help => 'Specify the log directory',
     :order => 5
   }


attribute 'jmx_port',
   :description => 'JMX Port',
   :required => 'required',
   :default               => '7199',
   :format => {
     :category => '1.Global',
     :help => 'Specify the port number through which you want to enable JMX RMI connections',
     :order => 6
   }
   
attribute 'enable_ssl',
    :description => 'Enable SSL',
    :default => 'false',
    :format => {
       :category => '2.SSL Configuration for Rest Proxy',
       :help => 'Enable SSL',
       :order => 1,
       :form => {'field' => 'checkbox'}
   }             
   
 attribute 'rest_truststore_password',
      :description => 'Rest Proxy Truststore password',
      :encrypted => true,
      :format => {
          :category => '2.SSL Configuration for Rest Proxy',
          :help => 'Truststore password. That can be shared with the clients.',
          :order => 2,
          :filter => {'all' => {'visible' => 'enable_ssl:eq:true'}}  	
 } 

 attribute 'client_auth_enable',
      :description => 'Client Auth enabled for Rest Proxy',
      :default => 'false',
      :format => {
          :category => '2.SSL Configuration for Rest Proxy',
          :help => 'Enable Client Auth',
          :order => 3,
          :form => {'field' => 'checkbox'},
          :filter => {'all' => {'visible' => 'enable_ssl:eq:true'}}  	
 }
attribute 'client_certs',
      :description => "Client Certificate location",
      :data_type => "array",
      :format => {
        :help => 'Client Truststore location. eg.certlocation',
        :category => '3.Client Certs Management.',
        :order => 1
 
 }
 
attribute 'show_restproxy_properties',
    :description => "Show Kafka rest proxy properties",
    :default => 'false',
    :format => {
        :category => '2.Kafka Rest Proxy Configuration Parameters',
        :help => 'Check this box only if you want to view or change the Kafka rest proxy related properties',
        :order => 1,
        :form => {'field' => 'checkbox'}
}

attribute 'restproxy_properties',
:description => "Customimze kafka-rest.properties for Kafka rest proxy configuration",
:data_type => "hash",
:default => '{"consumer.request.max.bytes":"67108864","consumer.request.timeout.ms":"305000","consumer.threads":"1","simpleconsumer.pool.size.max":"25"}',
:format => {
    :important => true,
    :help => 'Customize Kafka rest proxy config. Add new config if needed',
    :filter => {'all' => {'visible' => 'show_restproxy_properties:eq:true'}},
    :category => '2.Kafka Rest Proxy Configuration Parameters',
    :order => 2
}
 
#recipe "install", "Install Kafka Rest Proxy"
recipe "status", "Kafka Rest Proxy Status"
recipe "start", "Start Kafka Rest Proxy"
recipe "stop", "Stop Kafka Rest Proxy"
recipe "restart", "Restart Kafka Rest Proxy"
#recipe "clean", "Clean up Kafka Rest Proxy log directory"
