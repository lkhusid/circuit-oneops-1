name             'Mcrouter'
description      'Installs/Configures Mcrouter'
version          '0.1'
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
    :access => "global",
    :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
    :access => "global",
    :packages => [ 'bom' ]

attribute 'policy',
    :description => 'Delete/Update/Insert Behavior',
    :default => 'AllAsyncRoute',
    :format => {
        :category => '1.Global',
        :help => "Sets cache behavior for McRouter. See help documentation for more details.",
        :order => 1,
        :form => {'field' => 'select', 'options_for_select' => 
						[['Asynchronous All (default)', 'AllAsyncRoute'], ['Synchronous All', 'AllSyncRoute'], ['Synchronous Initial', 'AllInitialRoute'], ['Synchronous Fastest', 'AllFastestRoute'], ['Synchronous Majority', 'AllMajorityRoute']] }
    }

attribute 'message_AllAsyncRoute',
    :description => "Important Message",
    :default => "This policy has an availability bias and gives highest set ops throughput. It enables set ops to continue even if some cache replica(s) are down or unreachable. It follows the AllAsyncRoute for all set operations. McRouter will always return not_stored for all set operations. It will NOT wait to validate if the set operation was successful or not.",
    :data_type => 'text',
    :format => {
        :help => 'Important Message',
        :category => '1.Global',
        :order => 2,
        :filter => {'all' => {'visible' => 'policy:eq:AllAsyncRoute'}},
        :editable => false,
    }

attribute 'message_AllSyncRoute',
    :description => "Important Message",
    :default => "This policy has a consistency bias. Set ops will fail even if a single cache replica is down or unreachable. It follows the AllSyncRoute for all set operations. McRouter will perform all set ops synchronously and will return success only if it was successful in all replicas.",
    :data_type => 'text',
    :format => {
        :help => 'Important Message',
        :category => '1.Global',
        :order => 2,
        :filter => {'all' => {'visible' => 'policy:eq:AllSyncRoute'}},
        :editable => false,
    }

attribute 'message_AllInitialRoute',
    :description => "Important Message",
    :default => "This policy is a tradeoff between consistency and availability. Set ops will fail if the first replica in the children list is down. Request to the first replica is performed synchronously while requests to other replicas are completed asynchronously in the background.",
    :data_type => 'text',
    :format => {
        :help => 'Important Message',
        :category => '1.Global',
        :order => 2,
        :filter => {'all' => {'visible' => 'policy:eq:AllInitialRoute'}},
        :editable => false,
    }

attribute 'message_AllFastestRoute',
    :description => "Important Message",
    :default => "This policy is a tradeoff between consistency and availability. Set ops will fail only if all replicas in the children list are down. McRouter will return success after the first non-error reply from any replica. Other requests will complete asynchronously in the background.",
    :data_type => 'text',
    :format => {
        :help => 'Important Message',
        :category => '1.Global',
        :order => 2,
        :filter => {'all' => {'visible' => 'policy:eq:AllFastestRoute'}},
        :editable => false,
    }

attribute 'message_AllMajorityRoute',
    :description => "Important Message",
    :default => "This policy is a tradeoff between consistency and availability with a stronger consistency bias than AllFastestRoute and AllInitialRoute. Set ops will only succeed if a non-error result is returned by (half+1) replicas. McRouter will return the latest reply that it sees (typically the most common result is returned).",
    :data_type => 'text',
    :format => {
        :help => 'Important Message',
        :category => '1.Global',
        :order => 2,
        :filter => {'all' => {'visible' => 'policy:eq:AllMajorityRoute'}},
        :editable => false,
    }

attribute 'version',
          :description => 'McRouter version',
          :required => 'required',
          :default => '0.26.0-1.el7',
          :format => {
              :help => 'Enter the version number example: 0.26.0-1.el7',
              :category => '2.Advanced',
              :order => 3
          }

attribute 'port',
    :description => "McRouter Port",
    :default => "5000",
    :format => {
        :help => 'default port for McRouter',
        :category => '2.Advanced',
        :order => 3,
        :editable => false,
    }

attribute 'enable_asynclog',
    :description => "Enable Async Log",
    :default => 'true',
    :format => {
        :help => 'Enable async log file spooling',
        :category => '2.Advanced',
        :form => { 'field' => 'checkbox' },
        :order => 4
    }

attribute 'enable_flush_cmd',
    :description => "Enable flush_all command",
    :default => 'false',
    :format => {
        :help => 'Enable flush_all command',
        :category => '2.Advanced',
        :form => { 'field' => 'checkbox' },
        :order => 5
    }

attribute 'enable_logging_route',
    :description => "Enable LoggingRoute",
    :default => 'false',
    :format => {
        :help => 'Log every request via LoggingRoute.',
        :category => '2.Advanced',
        :form => { 'field' => 'checkbox' },
        :order => 6
    }

attribute 'num_proxies',
    :description => "Num Proxies",
    :default => "1",
    :format => {
        :help => 'Adjust how many proxy threads to run',
        :category => '2.Advanced',
        :order => 7,
    }

attribute 'server_timeout',
    :description => "Server Timeout",
    :default => "1000",
    :format => {
        :help => 'Timeout for talking to destination servers (e.g. memcached), in milliseconds. Must be greater than 0',
        :category => '2.Advanced',
        :order => 8,
    }

attribute 'verbosity',
    :description => 'Set Verbosity of VLOG',
    :default => 'disabled',
    :format => {
        :category => '2.Advanced',
        :help => "Set Verbosity of VLOG",
        :order => 9,
        :form => {'field' => 'select', 'options_for_select' => [['Disabled', 'disabled'], ['VLOG(0)', '0'], ['VLOG(1)', '1'], ['VLOG(2)', '2'], ['VLOG(3)', '3'], ['VLOG(4)', '4']] }
    }

attribute 'route',
    :description => 'Set route to use for McRouter',
    :default => 'PoolRoute',
    :format => {
        :category => '2.Advanced',
        :help => "Set route to use. Example PoolRoute or HashRouteSalted",
        :order => 10,
    }

attribute 'miss_limit',
    :description => 'Cache Miss Limit',
    :default => '2',
    :format => {
        :help => 'Limits the number of replicas to query in case of a cache miss. When a key is not in cache, Mcrouter will try finding the key in all replicas sequentially, each roundtrip adding up to the total response time. The recommended value is to match the number of replicas in local DC to avoid expensive roundtrips across DCs for cache misses. Zero or empty value means "unlimited".',
        :category => '2.Advanced',
        :order => 11,
        :pattern => '[0-9]*'
    }
attribute 'pool_group_by',
          :description => 'Pool Group By',
          :default => 'Cloud',
          :format => {
              :category => '2.Advanced',
              :help => "Pool Group By. Example Pool Group By: 'Cloud' or 'CloudFaultDomain'",
              :order => 12,
          }

attribute 'additional_cli_opts',
    :description => "Additional CLI Options",
    :data_type => 'array',
    :default => '[]',
    :format => {
        :help => 'Additional CLI Options',
        :category => '3.Additional Options',
        :order => 1
    }

recipe "status", "Mcrouter Status"
recipe "start", "Start Mcrouter"
recipe "stop", "Stop Mcrouter"
recipe "restart", "Restart Mcrouter"
