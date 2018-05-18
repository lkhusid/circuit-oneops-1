name 'Solr-service'
description 'Solr Service Cookbook'
version '1.0'

grouping 'default',
         :access   => 'global',
         :packages => ['base', 'mgmt.cloud.service', 'cloud.service'],
         :namespace => true

attribute 'solr_custom_params',
          :description => 'Solr custom configuration parameters',
          :default => '{}',
          :data_type => 'hash',
          :format => {
              :help => 'Solr custom configuration required to be provided here. For ex. block-expensive-queries-class',
              :category => '1.Custom Configuration',
              :order => 1
          }
