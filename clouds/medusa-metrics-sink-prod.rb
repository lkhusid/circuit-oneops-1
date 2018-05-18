name "medusa-metrics-sink-prod"
description "Cloud service for the sink (URL to the Kafka Broker)  where metrics for medusa (from telegraf agent) will be sent to"
  
service "medusa-metrics-sink-service",
  :cookbook => 'Medusa-Metrics-Sink',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),  
  :provides => { :service => 'monitoring' },
  :attributes => {
    :url => '',
  }
