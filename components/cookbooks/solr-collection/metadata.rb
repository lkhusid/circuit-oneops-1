name 'Solr-collection'
license 'All rights reserved'
version '1.0.0'

depends 'solrcloud'

grouping 'default',
  :access => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

grouping 'bom',
  :access => 'global',
  :packages => ['bom']

attribute 'collection_name',
  :description => 'Collection Name',
  :format => {
    :help => 'Collection Name',
    :category => '1.Collection Parameters',
    :order => 1
  }

attribute 'num_shards',
  :description => 'Number Of Shards',
  :format => {
    :help => 'Number of shards',
    :category => '1.Collection Parameters',
    :order => 2
  }

attribute 'replication_factor',
  :description => 'Replication Factor',
  :format => {
    :help => 'Replication Factor',
    :category => '1.Collection Parameters',
    :order => 3
  }

attribute 'max_shards_per_node',
  :description => 'Max Shards Per Node',
  :format => {
    :help => 'Max Shards Per Node',
    :category => '1.Collection Parameters',
    :order => 4
  }

attribute 'zk_config_urlbase',
  :description => 'URL for the config you want to upload to zookeeper',
  :format => {
    :help => 'Please double-check the version of the config in the URL',
    :category => '1.Collection Parameters',
    :order => 5
  }

attribute 'config_name',
  :description => 'Name of the configuration in zookeeper',
  :format => {
    :help => 'Every Solr collection requires a configuration in zookeeper having solrconfig.xml, managed-schema etc files. This is the name of that configuration',
    :category => '1.Collection Parameters',
    :order => 6
  }

attribute 'date_safety_check_for_config_update',
  :description => 'Date on which file is uploaded (YYYY-mm-DD)',
  :required => 'required',
  :format => {
    :help => 'Safety check to ensure that you do not accidentally overwrite the configuration in zookeeper. Please provide today\'s date in YYYY-mm-DD format to indicate that you do want to overwrite the configuration.',
    :category => '1.Collection Parameters',
    :order => 7
  }

# Enable this flag to RELOAD the collection cores. Keeping the default as true as we don't see any issues with reload upon any configuration change in ZK
attribute 'allow_auto_reload_collection',
  :description => 'Reload the collection if there is an update on the ZK config',
  :default => "true",
  :format => {
    :category => '1.Collection Parameters',
    :help => 'This will reload the collection cores if it exists and if there is an update on the ZK config',
    :form => {'field' => 'checkbox'},
    :order => 8
  }

# attribute 'auto_add_replicas',
#   :description => 'Auto Add Replicas',
#   :default => 'false',
#   :format => {
#     :help => 'When set to true, enables auto addition of replicas.',
#     :category => '1.Collection Parameters',
#     :form => {'field' => 'select', 'options_for_select' => [['false', 'false'],['true', 'true']]},
#     :order => 6
#   }

attribute 'skip_collection_comp_execution',
  :description => 'Skip collection component',
  :default => "false",
  :format => {
    :category => '1.Collection Parameters',
    :help => 'Select this option when you want to skip the the collection component deployment. You may want to skip it when the computes are replaced or added.',
    :form => {'field' => 'checkbox'},
    :order => 10
  }

attribute 'autocommit_maxtime',
          :description  => "autocommit maxtime",
          :default => "300000",
          :format => {
              :help => 'The maximum time after which a hard commit will be issued automatically. The value needs to be provided in milliseconds unit. The hard commit is an expensive operation, it is advisable to perform hard commits less frequently. ',
              :category => '2.UpdateHandler',
              :order => 10
          }

attribute 'autocommit_maxdocs',
          :description  => "autocommit maxdocs",
          :default => '-1',
          :format => {
              :help => 'The maximum number of docs ingested after which a hard commit will be issued automcatically. The hard commit is an expensive operation, it is advisable to perform hard commits less frequently',
              :category => '2.UpdateHandler',
              :order => 11
          }

attribute 'autosoftcommit_maxtime',
          :description  => "autosoftcommit maxtime",
          :default => '30000',
          :format => {
              :help => 'The maximum time after which a soft commit will be issued automatically. The value needs to be provided in milliseconds unit. The soft commit makes the documents ingested visiable to future searches. The frequent opening of the serachers is not good for the performance',
              :category => '2.UpdateHandler',
              :order => 12
          }

attribute 'updatelog_numrecordstokeep',
          :description  => "updatelog numrecordstokeep",
          :default => '50000',
          :format => {
              :help => 'This parameter is useful for recovery purposes. If the replica is behind by number of documents less than numRecordsToKeep it recovers from the update log of the leader, otherwise it performans a full replica recover',
              :category => '2.UpdateHandler',
              :order => 14
          }

attribute 'updatelog_maxnumlogstokeep',
          :description  => "updatelog maxnumlogstokeep",
          :default => '10',
          :format => {
              :help => 'The maximum number of update logs to keep. Solr writes every document to a transaction log which is also referred to as Update log. This log is used by replicas for recovery purposes.',
              :category => '2.UpdateHandler',
              :order => 15
          }

attribute 'mergepolicyfactory_maxmergeatonce',
          :description  => "mergepolicyfactory maxmergeatonce",
          :required => false,
          :default => '10',
          :format => {
              :help => 'The maximum number of segments to be merged at a time, for read heavy loads use a value less than 10',
              :category => '2.UpdateHandler',
              :order => 16
          }

attribute 'mergepolicyfactory_segmentspertier',
          :description  => "mergepolicyfactory segmentspertier",
          :required => false,
          :default => '10',
          :format => {
              :help => 'The maximum number of segments merged Per Tier. The TieredMergePolicy merges segments of equal size together which it considers as one tier. This parameter should always be greater than or equal to maxMergedAtOnce',
              :category => '2.UpdateHandler',
              :order => 17
          }
attribute 'rambuffersizemb',
          :description  => "rambuffersizemb",
          :required => false,
          :default => '120',
          :format => {
              :help => 'The threshold of memory in MB when reached, the documents will be flushed to hard disk',
              :category => '2.UpdateHandler',
              :order => 18
          }

attribute 'maxbuffereddocs',
          :description  => "maxbuffereddocs",
          :required => false,
          :default => '10000',
          :format => {
              :help => 'The threshold for number of documents in memory, after which the documents will be flushed to hard disk',
              :category => '2.UpdateHandler',
              :order => 19
          }

attribute 'min_rf',
          :description  => "minimum replication factor",
          :default => '',
          :format => {
              :help => 'The minimum replication factor(min_rf) parameter on update request cause the server to return the achieved replication factor in the response. This does not mean Solr will enforce a minimum replication factor as Solr does not support rolling back updates that succeed on a subset of replicas.',
              :category => '2.UpdateHandler',
              :order => 20
          }

attribute 'filtercache_size',
          :description  => "filtercache size",
          :required => false,
          :default => '128',
          :format => {
              :help => 'The maximum size of Cache used for caching filter queries',
              :category => '3.Query',
              :order => 21
          }

attribute 'queryresultcache_size',
          :description  => "queryresultcache size",
          :required => false,
          :default => '128',
          :format => {
              :help => 'The maximum size of cache for storing QueryResults',
              :category => '3.Query',
              :order => 22
          }

attribute 'request_select_defaults_timeallowed',
          :description  => "Request time allowed",
          :format => {
              :help => 'The amount of time after which the select queries will be timed out by Solr. So queries which take longer than this value will fail and Solr will cancel these queries.',
              :category => '3.Query',
              :order => 23
          }

attribute 'validation_enabled',
          :description  => "Validation enabled",
          :format => {
              :help => 'If selected, this will enable validation. ex. mandatory check for ignore-commit-from-client in UpdateRequestProcessorChain',
              :form => { 'field' => 'checkbox' },
              :category => '3.Query',
              :order => 24
          }

attribute 'block_expensive_queries',
          :description  => "Block Expensive Queries",
          :default => "true",
          :format => {
              :help => 'If selected, this will Block Expensive Queries. eg: q=*:*&start=0&rows=101 is expensive if max documents fetch allowed is 100',
              :form => { 'field' => 'checkbox' },
              :category => '4.Block Expensive Queries',
              :order => 25
          }

attribute 'max_start_offset',
          :description  => "maxStartOffset",
          :default => "1000",
          :format => {
              :help => 'The maximum value allowed for the "start" param in a Solr query. The queries with a value for start param larger than this value will be failed',
              :category => '4.Block Expensive Queries',
              :filter => {'all' => {'visible' => 'block_expensive_queries:eq:true'}},
              :order => 26
          }

attribute 'max_rows_fetch',
          :description  => "maxRowsFetch for Block Expensive Queries",
          :default => "100",
          :format => {
              :help => 'The maximum number of documents that are allowed to fetch in a single Solr query. The queries with a value for "rows" param larger than this value will be failed',
              :category => '4.Block Expensive Queries',
              :filter => {'all' => {'visible' => 'block_expensive_queries:eq:true'}},
              :order => 27
          }

attribute 'enable_slow_query_logger',
          :description  => "Enable Slow Query Logger",
          :default => "true",
          :format => {
              :help => 'If selected, this will enable slow Query logger. eg: ',
              :form => { 'field' => 'checkbox' },
              :category => '5.Slow Query Logger',
              :order => 28
          }

attribute 'slow_query_threshold_millis',
          :description => 'Slow Query Threshold (in ms)',
          :default => "1000",
          :format => {
              :category => '5.Slow Query Logger',
              :help => 'Provide the slow query threshold in milli seconds to log the slow queries to solr.log',
              :order => 29
          }

attribute 'enable_query_source_tracker',
          :description  => "Enable Query Source Tracker",
          :default => "false",
          :format => {
              :help => 'If selected, the customers are expected to pass in a new Solr query param called as "qi" when querying from their application or directly using curl.',
              :form => { 'field' => 'checkbox' },
              :category => '6.Query Source Tracker',
              :order => 30
          }

attribute 'query_identifiers',
          :description => 'Query Identifiers',
          :default => "{}",
          :data_type => 'array',
          :format => {
              :help => "The customers are expected to come up with valid values for qi param for each of their Application use cases.",
              :category => '6.Query Source Tracker',
              :filter => {'all' => {'visible' => 'enable_query_source_tracker:eq:true'}},
              :order => 31
          }

attribute 'enable_fail_queries',
          :description  => "Enable Fail Queries",
          :default => "false",
          :format => {
              :help => 'If true the component will also collect queries per second metric for each qi value, if false it will not collect any metrics',
              :form => { 'field' => 'checkbox' },
              :category => '6.Query Source Tracker',
              :filter => {'all' => {'visible' => 'enable_query_source_tracker:eq:true'}},
              :order => 32
          }

attribute 'backup_enabled',
          :description => 'Enable backup',
          :required => 'required',
          :format => {
            :help => 'Schedule back-up of Solr indexes at regular intervals. You must add cinder-backed storage for this to work and that storage should be large enough to store about 3 backups of the maximum index you will have on any compute.',
            :category => '8.Solr Backup',
            :order => 1,
            :form => { 'field' => 'checkbox' }
          }

attribute 'backup_cron',
          :description => 'Backup Schedule',
          :format => {
              :help => "Solr backup cron scedule (minute hour day_of_month month day_of_week) ex for every 10 min=> */10 * * * 1",
              :category => '8.Solr Backup',
              :filter => {"all" => {"visible" => ('backup_enabled:eq:true')}},
              :order => 2
          }

attribute 'backup_location',
          :description => 'Backup Location',
          :format => {
              :help => "Solr backup directory",
              :category => '8.Solr Backup',
              :filter => {"all" => {"visible" => ('backup_enabled:eq:true')}},
              :order => 3
          }

attribute 'backup_number_to_keep',
          :description => 'The number of backups to keep',
          :format => {
              :help => "This integer value will be used decide how many old backups to keep while deleting previous backups.",
              :category => '8.Solr Backup',
              :filter => {"all" => {"visible" => ('backup_enabled:eq:true')}},
              :order => 4
          }
              
attribute 'collections_for_node_sharing',
          :description  => "Collection-list for sharing nodes",
          :default => "{}",
          :data_type => 'array',
          :format => {
              :help => 'Provide a list of all the collection-names with whom this collection will share its nodes to save hardware. All collection components in a group of shared collections must provide the names of all shared collections in their group',
              :category => '7.Node sharing to save hardware',
              :order => 32
          }

attribute 'nodeip',
          :description => 'IPAddress',
          :default => "",
          :grouping => 'bom',
          :format => {
              :important => true,
              :help => 'Node IPAddress (used during replace)',
              :category => '10.Operations Attributes',
              :order => 33
          }

attribute 'first_compute_after_sort',
          :description => 'Running collection component (i.e. first compute after sorting computes)?',
          :default => "",
          :grouping => 'bom',
          :format => {
              :important => true,
              :help => 'First compute after sort (for running collection component)',
              :category => '10.Operations Attributes',
              :order => 34
          }

# attribute 'documentcache_size',
#           :description  => "documentcache_size",
#           :required => false,
#           :default => '128',
#           :format => {
#               :help => 'The maximum size of FilterCache',
#               :category => '3.Query',
#               :order => 22
#           }

# attribute 'queryresultmaxdoccached',
#           :description  => "queryresultmaxdoccached",
#           :required => false,
#           :default => '200',
#           :format => {
#               :help => 'The maximum size of FilterCache',
#               :category => '3.Query',
#               :order => 23
#           }



attribute 'estimate_two_year_doc_count',
  :description => 'Number of documents in 2 years',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => 'Do not provision the cluster thinking of current or next month needs only. It is hard to re-distribute shards later on',
    :order => 41
  }

attribute 'estimate_avg_doc_size_kb',
  :description => 'Average document size (kB)',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "Do not calculate document size from a single document's size on disk. Getting an average from several hundred docs representing a variety of your document types",
    :order => 42
  }

attribute 'estimate_avg_nested_docs_per_doc',
  :description => 'Average number of nested docs per doc',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "Average number of nested documents per root-level document",
    :order => 43
  }


attribute 'estimate_indexed_fields_per_doc',
  :description => 'Average indexed fields per doc',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "Minimizing indexed fields per document increases performance",
    :order => 44
  }


attribute 'estimate_stored_fields_per_doc',
  :description => 'Average stored fields per doc',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "Minimizing stored fields per document increases performance",
    :order => 45
  }


attribute 'ttl_field',
  :description => 'Date field used to expire documents',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "A date field is recommended to expire documents such that document count remains under control",
    :order => 46
  }


attribute 'ttl_in_days',
  :description => 'Document expiry (in days)',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "After how many days, the document should be expired based on the above date field",
    :order => 47
  }


attribute 'estimate_peak_updates_per_sec',
  :description => 'Approx peak updates per second',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "Peak rate of write queries per second",
    :order => 48
  }


attribute 'estimate_peak_reads_per_sec',
  :description => 'Approx peak reads per second',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "Peak rate of read queries per second",
    :order => 49
  }


attribute 'estimate_peak_facets_per_sec',
  :description => 'Approx peak facets per second',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "You MUST rethink your usage if you expect more than 50 facet queries per second",
    :order => 50
  }


attribute 'estimate_peak_pivots_per_sec',
  :description => 'Approx peak pivots per second',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "You MUST rethink your usage if you expect more than 10 pivot queries per second",
    :order => 51
  }


attribute 'estimate_peak_paginations_per_sec',
  :description => 'Approx peak pagination queries per second',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "You MUST rethink your usage if you expect more than 20 pagination queries per second",
    :order => 52
  }


attribute 'estimate_peak_geospatials_per_sec',
  :description => 'Approx peak geo-spatial queries per second',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "You MUST rethink your usage if you expect more than 20 geo-spatial queries per second",
    :order => 53
  }


attribute 'estimate_peak_blockjoins_per_sec',
  :description => 'Approx peak blockjoins per second',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "You MUST rethink your usage if you expect more than 50 blockjoin queries per second",
    :order => 54
  }


attribute 'estimate_full_ingestion_minutes',
  :description => 'Approx minutes for full re-ingestion',
  :default => "",
  :format => {
    :category => '9.Cluster Sizing Estimates',
    :help => "An approximate time that is required to re-index all the documents in Solr",
    :order => 55
  }


######################################
## Actions in the Operations Phase  ##
######################################

recipe "clusterstate",
  :description => 'Deletes all the dead/down replicas and update cluster state.',
  :args => {
    "collection_name" => {
      "name" => "collection_name",
      "description" => "collection name",
      "dataType" => "string"
    }
 }

recipe "managedschema",
  :description => 'Add/Delete/Replace/ fields,field types,copy fields etc., in managed schema of collection config.',
  :args => {
    "schema_action" => {
      "name" => "schema_action",
      "description" => "Provide the schema action(add/delete/replace field/field-types etc.,)",
      "required" => true,
      "dataType" => "string"
    },
    "json_payload" => {
      "name" => "json_payload",
      "description" => "Json payload of the specified action",
      "required" => true,
      "dataType" => "string"
    },
    "update_timeout_secs" => {
      "name" => "update_timeout_secs",
      "description" => "Update Timeout in Secs",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "solrconfig",
  :description => 'Update common/user-defined properties in solr config file.',
  :args => {
    "property_type" => {
      "name" => "property_type",
      "description" => "common-property/user-defined-property",
      "required" => true,
      "dataType" => "string"
    },
    "property_name" => {
      "name" => "property_name",
      "description" => "Provide the specific property name to update",
      "required" => true,
      "dataType" => "string"
    },
    "property_value" => {
      "name" => "property_value",
      "description" => "Provide the property value of specific property",
      "required" => true,
      "dataType" => "string"
    }
  }

recipe "reload_collection",
  :description => 'Reloads the collection/ core',
  :args => {
    "collection_name" => {
    "name" => "collection_name",
    "description" => "collection name",
    "dataType" => "string"
    }
  }
recipe "backup_core",
  :description => 'Backup solr core',
  :args => {
    "collection_name" => {
      "name" => "collection_name",
      "description" => "collection name",
      "dataType" => "string"
    }
  }
recipe "restore_core",
  :description => 'Restore solr core',
  :args => {
    "collection_name" => {
          "name" => "collection_name",
          "description" => "collection name",
          "dataType" => "string"
        },
    "backup_datetime" => {
          "name" => "backup_datetime",
          "description" => "backup datetime yyyy_mm_dd_hh_mm_ss",
          "defaultValue"=> "2017_10_31_00_00_00",
          "dataType" => "string"
        }
  }  
recipe "backup_restore_status",
  :description => 'Status of backup/restore',
  :args => {
    "collection_name" => {
      "name" => "collection_name",
      "description" => "collection name",
      "dataType" => "string"
    },
    "backup_or_restore" => {
      "name" => "backup_or_restore",
      "description" => "Backup/Restore?",
      "defaultValue"=> "Backup",
      "dataType" => "string"
    }
  }
  



