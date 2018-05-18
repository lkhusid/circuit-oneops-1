name "meghacache"
description "MeghaCache"
category "Other"
type		'Platform'

environment "single", {}
environment "redundant", {}

include_pack "base"

platform :attributes => {'autoreplace' => 'true',
                         "replace_after_minutes" => 1440,
                         "replace_after_repairs" => 100
          }
resource 'compute',
          :cookbook => 'oneops.1.compute',
         :attributes => { 'size' => 'M' }

resource "os",
  :cookbook => "oneops.1.os",
  :attributes => { "ostype"  => "centos-7.2", "dhclient" => 'true' }

resource 'user-app',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'app',
             'description' => 'App-User',
             'home_directory' => '/app/',
             'system_account' => true,
             'sudoer' => true
         }

resource 'user-mcrouter',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'mcrouter',
             'description' => 'McRouter-User',
             'home_directory' => '/opt/mcrouter',
             'system_account' => true,
             'sudoer' => true
         }

resource 'user-memcached',
         :cookbook => 'oneops.1.user',
         :design => true,
         :requires => {'constraint' => '1..1'},
         :attributes => {
             'username' => 'memcached',
             'description' => 'Memcached-User',
             'home_directory' => '/opt/memcached',
             'system_account' => true,
             'sudoer' => true
         }

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0", "5000 5000 tcp 0.0.0.0/0", "11211 11211 tcp 0.0.0.0/0"]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource 'mcrouter',
         :cookbook => 'oneops.1.mcrouter',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :help => 'MeghaCache McRouter',
             :services => 'mirror'
         },
         :payloads => {
             'clouds' => {
             'description' => 'Clouds',
             'definition' => '{
                 "returnObject": false,
                 "returnRelation": false,
                 "relationName": "base.RealizedAs",
                 "direction": "to",
                 "targetClassName": "manifest.oneops.1.Mcrouter",
                 "relations": [{
                     "returnObject": false,
                     "returnRelation": false,
                     "relationName": "manifest.Requires",
                     "direction": "to",
                     "targetClassName": "manifest.Platform",
                     "relations": [{
                         "returnObject": true,
                         "returnRelation": false,
                         "relationName": "base.Consumes",
                         "direction": "from",
                         "targetClassName": "account.Cloud"
                     }]
                 }]
             }'}
         }

resource 'memcached',
         :cookbook => 'oneops.1.memcached',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :help => 'MeghaCache Memcached',
             :services => 'mirror'
         },
         :monitors => {
             'MemcachedStats' => {:description => 'Memcached statistics',
                 :source => '',
                 :cmd => 'check_memcached_stats',
                 :cmd_line => '/opt/nagios/libexec/check_memcached_stats.rb',
                 :metrics => {
                     'bytes' => metric(:unit => 'bytes', :description => 'Memory in use'),
                     'bytes_per_sec' => metric(:unit => 'bytes', :description => 'Memory usage change per second'),
                     'cmd_get_per_sec' => metric(:unit => 'cmd_get_per_sec', :description => 'Number of gets per second'),
                     'cmd_set_per_sec' => metric(:unit => 'cmd_set_per_sec', :description => 'Number of sets per second'),
                     'get_hits_per_sec'=> metric(:unit => 'get_hits_per_sec', :description => 'Number of hits per second'),
                     'get_misses_per_sec'=> metric(:unit => 'get_misses_per_sec', :description => 'Number of Misses per second'),
                     'evictions_per_sec'=> metric(:unit => 'evictions_per_sec', :description => 'Number of evictions per second'),
                     'bytes_used_percent'=> metric(:unit => '%', :description => 'Percent of Memory in use'),
                 },
                 :thresholds => {
                     'BytesUsedPercent' => threshold('1m', 'avg', 'bytes_used_percent', trigger('>=', 60, 5, 1), reset('<', 60, 5, 1)),
                     'EvictionsPerSecond' => threshold('1m', 'avg', 'evictions_per_sec', trigger('>', 0, 5, 1), reset('<=', 0, 5, 1)),
                 }
             },
         }

resource "hostname",
        :cookbook => "oneops.1.fqdn",
        :design => true,
        :requires => {
             :constraint => "1..1",
             :services => "dns",
             :help => "hostname dns entry"
         }

resource 'meghacache',
         :cookbook => 'oneops.1.meghacache',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :help => 'MeghaCache'
         },
         :monitors => {
             'process-status' => {
                 :description => 'Process Status',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_meghacache_process',
                 :cmd_line => '/opt/nagios/libexec/check_meghacache_process.sh',
                 :metrics => {
                     'mcrouter-status' => metric(:unit => '', :description => 'Mcrouter Process Status', :dstype => 'GAUGE'),
                     'memcached-status' => metric(:unit => '', :description => 'Memcached Process Status', :dstype => 'GAUGE'),
                 },
                 :thresholds => {
                     'McrouterProcessStatusExceptions' => threshold('1m', 'avg', 'mcrouter-status', trigger('<', 1, 5, 1), reset('>=', 1, 5, 1), 'unhealthy'),
                     'MemcachedProcessStatusExceptions' => threshold('1m', 'avg', 'memcached-status', trigger('<', 1, 5, 1), reset('>=', 1, 5, 1), 'unhealthy'),
                 }
              }
         },
         :payloads => {
              'memcached' => {
              'description' => 'memcached custom payload',
              'definition' => '{
                 "returnObject": false,
                 "returnRelation": false,
                 "relationName": "bom.DependsOn",
                 "direction": "from",
                 "targetClassName": "bom.oneops.1.Mcrouter",
                 "relations": [
                   { "returnObject": true,
                     "returnRelation": false,
                     "relationName": "bom.DependsOn",
                     "direction": "from",
                     "targetClassName": "bom.oneops.1.Memcached"

                   }
                  ]
               }'
             }
            }

resource "meghacache-cluster",
         :except => [ 'single' ],
         :cookbook => "oneops.1.meghacache-cluster",
         :design => false,
         :requires => {
             :constraint => "1..1"
         }


# depends_on
[
    {:from => 'user-app', :to => 'os'},
    {:from => 'user-memcached', :to => 'os'},
    {:from => 'user-mcrouter', :to => 'os'},
    {:from => 'memcached', :to => 'user-memcached'},
    {:from => 'mcrouter', :to => 'user-mcrouter'},
    {:from => 'telegraf', :to => 'meghacache'},
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

relation "meghacache-cluster::depends_on_flex::meghacache",
         :except => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'meghacache-cluster',
         :to_resource => 'meghacache',
         :attributes => {"propagate_to" => 'to', "flex" => true, "current" => 2, "min" => 2, "max" => 100}

relation "fqdn::depends_on::meghacache-cluster",
         :except => [ '_default', 'single' ],
         :relation_name => 'DependsOn',
         :from_resource => 'fqdn',
         :to_resource   => 'meghacache-cluster',
         :attributes    => { "propagate_to" => 'both', "flex" => false }

# depends_on with propagate_to
[
    {:from => 'meghacache', :to => 'mcrouter', :propagate_to => 'to'},
    {:from => 'mcrouter', :to => 'memcached', :propagate_to => 'none'},
].each do |link|
    relation "#{link[:from]}::depends_on::#{link[:to]}::propagate_to::#{link[:propagate_to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource => link[:to],
    :attributes => {"propagate_to" => link[:propagate_to], "flex" => false, "min" => 1, "max" => 1}
end

# ManagedVia
[ 'meghacache', 'mcrouter', 'memcached', 'user-app', 'user-mcrouter', 'user-memcached'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => [ '_default' ],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource   => 'compute',
           :attributes    => { }
end

# ManagedVia - except single
[ 'meghacache-cluster' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default', 'single' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
