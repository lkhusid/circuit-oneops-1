name             'Mirrormaker'
maintainer       'Platform Messaging'
maintainer_email 'GECMSGDE54@email.wal-mart.com'
license          'All rights reserved'
description      'Installs/Configures mirrormaker'
version          '0.0.1'

grouping 'default',
         :access => "global",
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'version',
  :description          => 'Version of Mirrormaker',
  :required => "required",
  :default               => '0.10.1.0',
  :format => {
    :category => '1.Global',
    :help => 'Version of the mirrormaker',
    :order => 1,
    :form => {'field' => 'select', 'options_for_select' => [['0.10.1.0', '0.10.1.0']]}
  }

attribute 'log_dir',
   :description          => 'Log Directory',
   :required => 'required',
   :default               => '/mirrormaker/log',
   :format => {
     :category => '1.Global',
     :help => 'Specify the log directory',
     :order => 2
   }

attribute 'config_dir',
   :description          => 'Config Directory',
   :required => 'required',
   :default               => '/mirrormaker/config',
   :format => {
     :category => '1.Global',
     :help => 'Specify the configuration directory',
     :order => 3
   }

attribute 'consumer_config_dir',
   :description          => 'Consumer Config Directory',
   :required => 'required',
   :default               => '/mirrormaker/config',
   :format => {
     :category => '1.Global',
     :help => 'Specify the directory of consumer configuration file',
     :order => 4
   }

attribute 'producer_config_dir',
   :description          => 'Producer Config Directory',
   :required => 'required',
   :default               => '/mirrormaker/config',
   :format => {
     :category => '1.Global',
     :help => 'Specify the directory of producer configuration file',
     :order => 5
   }

attribute 'zookeeper_connect_for_consumer',
   :description          => 'Kafka Endpoint for Consumer',
   :required => 'required',
   :default               => '## Please specify the zookeeper (server:port) connections ##',
   :format => {
     :category => '2.Consumer Configuration Parameters',
     :help => 'List all the zookeeper (server:port) connections',
     :order => 1,
     :pattern => '.+\:[0-9]+'
   }

attribute 'consumer_group_id',
  :description          => 'Consumer Group ID',
  :required => 'required',
  :default               => 'KafkaMirror',
  :format => {
    :category => '2.Consumer Configuration Parameters',
    :help => 'Consumer group ID',
    :order => 2
}

attribute 'consumer_properties',
   :description          => 'consumer.properties',
   :data_type => "hash",
   :default               => '{"auto.offset.reset":"earliest"}',
   :format => {
     :category => '2.Consumer Configuration Parameters',
     :help => 'Customize consumer.properties for MirrorMaker. Add new parameters if needed',
     :order => 3
   }

attribute 'broker_list_for_producer',
   :description          => 'Kafka Endpoint for Producer',
   :required => 'required',
   :default               => '## Please specify the brokers (server:port) connections ##',
   :format => {
     :category => '3.Producer Configuration Parameters',
     :help => 'List all the brokers (server:port) for producer',
     :order => 1,
     :pattern => '.+\:[0-9]+'
   }

attribute 'producer_properties',
  :description => 'producer.properties',
  :data_type => "hash",
  :default               => '{}',
  :format => {
    :category => '3.Producer Configuration Parameters',
    :help => 'Customize producer.properties for MirrorMaker. Add new parameters if needed',
    :order => 2
  }

attribute 'whitelist',
   :description          => 'List of Topics to Mirror',
   :required => 'required',
   :default               => '## Please specify the topic to mirror ##',
   :format => {
     :category => '4.Mirrormaker Configuration Parameters',
     :help => 'List all the topics which mirrormaker will mirror, for example: "topic1|topic2"',
     :order => 1,
   }

attribute 'topic_map_list',
   :description          => 'List of Topics to Mirror and Rename (optional)',
   :default               => '',
   :format => {
     :category => '4.Mirrormaker Configuration Parameters',
     :help => 'List all the topics which mirrormaker will mirror and rename, for example: "topic1:topic1-new,topic2:topic2-new"',
     :order => 2,
   }

attribute 'mirrormaker_properties',
   :description          => 'mirrormaker.properties',
   :data_type => "hash",
   :default               => '{"num.streams":"3"}',
   :format => {
    :category => '4.Mirrormaker Configuration Parameters',
    :help => 'Customize mirrormaker.properties for MirrorMaker. Add new parameters if needed',
    :order => 3
}

attribute 'enable_ssl_for_consumer',
  :description => 'Enable SSL for consuming from a secure Kafka cluster?',
  :default => 'false',
  :format => {
   :category => '5.SSL Configuration for MirrorMaker',
   :help => 'Enable SSL',
   :order => 1,
   :form => {'field' => 'checkbox'}
 }

attribute 'enable_ssl_for_producer',
  :description => 'Enable SSL for producing to a secure Kafka cluster?',
  :default => 'false',
  :format => {
  :category => '5.SSL Configuration for MirrorMaker',
  :help => 'Enable SSL',
  :order => 2,
  :form => {'field' => 'checkbox'}
}

 attribute 'mm_truststore_password',
      :description => 'MirrorMaker Truststore password',
      :encrypted => true,
      :format => {
          :category => '5.SSL Configuration for MirrorMaker',
          :help => 'Truststore password.',
          :order => 3,
          :filter => {'all' => {'visible' => 'enable_ssl_for_consumer:eq:true || enable_ssl_for_producer:eq:true'}}
 }

attribute 'client_certs',
      :description => "Client Certificate location",
      :data_type => "array",
      :format => {
        :help => 'Client Truststore location. eg.certlocation',
        :category => '5.SSL Configuration for MirrorMaker',
        :order => 4,
        :filter => {'all' => {'visible' => 'enable_ssl_for_consumer:eq:true || enable_ssl_for_producer:eq:true'}}

 }

recipe "status", "Mirrormaker Status"
recipe "start", "Start Mirrormaker"
recipe "stop", "Stop Mirrormaker"
recipe "restart", "Restart Mirrormaker"
recipe "repair", "Repair Mirrormaker"
recipe "clean", "Clean up MirrorMaker log directory"
