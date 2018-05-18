# Solr global configuration cloud service.
# This service is used to provide the solr custom configurations. This service should be added as cloud service for all the clouds which are being used in the transition.
# In solrcloud & solr-collection cookbook will use this service to access various custom configurations defined as attributes
name 'solr-service'
description 'Solr Service'
auth 'solrsecretkey'

service 'solr-service',
        :description => 'Solr custom configuration',
        :cookbook => 'solr-service',
        :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
        :provides => {:service => 'solr-service'},
        :attributes => {
            :solr_custom_params => '{
              "block_expensive_queries_class": "",
              "slow_query_logger_class": "",
              "query_source_tracker_class": "",
              "solr_dosfilter_class": "",
              "df_graphite_servers": "[]",
              "release_urlbase": "",
              "snapshot_urlbase": "",
              "solr_custom_comp_artifact": "",
              "slow_query_logger": "",
              "delete_query_logger": "",
              "jetty_filter_url": "",
              "config_url_v5": "",
              "config_url_v6": "",
              "config_url_v7": "",
              "solr_monitor_artifact": ""
            }'
        }
