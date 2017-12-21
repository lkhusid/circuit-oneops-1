name             "Kafka_console"
maintainer       "Messaging Team"
maintainer_email "GECMSGDE54@email.wal-mart.com"
license          "All rights reserved"
description	 "Install/Configure kafka"
version          "0.0.1"
description      "Kafka web console is a web-based user interface to let users manage and monitor Kafka cluster."

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

# installation attributes

attribute 'jvm_args',
  :description          => 'JVM Parameters',
  :default               => '',
  :format => {
    :category => '1.Global',
    :help => 'JVM parameters to run Kafka Manager',
    :order => 4
}

attribute 'authenabled',
  :description => "Enable Authentication",
  :default => 'false',
  :format => {
    :category => '3.Kafka Console Configuration',
    :help => 'Check this box only if want to use external Zookeeper',
    :order => 1,
    :form => {'field' => 'checkbox'}
}

attribute 'mgr_username',
:description => 'Username',
:format => {
  :help => 'Username for the Kafka manager',
  :category => '3.Kafka Console Configuration',
  :order => 2,
  :filter => {'all' => {'visible' => 'authenabled:eq:true'}}

}

attribute 'mgr_password',
:description => 'Password',
:encrypted => true,
:format => {
  :help => 'Password for the Kafka manager',
  :category => '3.Kafka Console Configuration',
  :order => 3,
  :filter => {'all' => {'visible' => 'authenabled:eq:true'}}
}

attribute 'app_features',
    :description => "Application Features",
    :data_type => "array",
    :default => '["KMClusterManagerFeature","KMTopicManagerFeature","KMPreferredReplicaElectionFeature","KMReassignPartitionsFeature"]',
    :format => {
        :help => 'Customize Application Features (like Add/update topic, partitions etc)',
        :category => '3.Kafka Console Configuration',
        :order => 4
}
recipe "status", "Kafka Manager Status"
recipe "start", "Start Kafka Manager"
recipe "stop", "Stop Kafka Manager"
recipe "restart", "Restart Kafka Manager"
recipe "repair", "Repair Kafka Manager"
recipe "clean", "Cleanup Kafka Manager"
