include_pack "genericlb"

name "bigdata-client-v1"
description "Big Data Client (V1 Build)"
type "Platform"
category "Other"

# Versioning attributes
spark_version = "1"
spark_cookbook = "oneops.1.spark-v#{spark_version}"
yarn_version = "1"
yarn_config_cookbook = "oneops.1.hadoop-yarn-config-v#{yarn_version}"
yarn_cookbook = "oneops.1.hadoop-yarn-v#{yarn_version}"
# When changing version, need to change the class name in payload definitions.

platform :attributes => {'autoreplace' => 'false'}

# Define resources for a standalone Spark client
resource 'secgroup',
         :cookbook   => 'oneops.1.secgroup',
         :design     => true,
         :attributes => {
           # Port configuration:
           #
           #  null:  Ping
           #    22:  SSH
           #  4000:  Spark Client Driver
           #  4040-
           #  4049:  Spark Application UI
           #  7077:  Spark master
           #  8080:  Spark master UI
           #  8081:  Spark worker UI
           # 10001:  Spark Thrift Server
           # 18080:  Spark History Server UI
           # 60000:  For mosh
           #
           "inbound" => '[
               "null null 4 0.0.0.0/0",
               "22 22 tcp 0.0.0.0/0",
               "4000 4000 tcp 0.0.0.0/0",
               "4040 4049 tcp 0.0.0.0/0",
               "7077 7077 tcp 0.0.0.0/0",
               "8080 8081 tcp 0.0.0.0/0",
               "10001 10001 tcp 0.0.0.0/0",
               "18080 18080 tcp 0.0.0.0/0",
               "60000 60100 udp 0.0.0.0/0"
           ]'
         },
         :requires   => {
           :constraint => '1..1',
           :services   => 'compute'
         }

resource "lb",
         :except => [ 'single' ],
         :design => false,
         :cookbook => "oneops.1.lb",
         :requires => { "constraint" => "1..1", "services" => "compute,lb,dns" },
         :attributes => {
           "listeners" => '[ "tcp 22 tcp 22" ]'
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => 'mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {
           'flavor' => 'oracle',
           'jrejdk' => 'server-jre'
         }

resource "hadoop-yarn-config",
         :cookbook => yarn_config_cookbook,
         :design => true,
         :requires => {
             :constraint => "1..1",
             :services => "dns",
             :help => "client"
         }

resource "centrify",
         :cookbook => "oneops.1.centrify-vb1",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :services => "centrify",
             :help => "Centrify AD authentication for Linux"
         },
         :attributes => { }

resource "client-yarn",
         :cookbook => yarn_cookbook,
         :design => true,
         :requires => {
             :constraint => "1..1",
             :services => "dns",
             :help => "resource manager"
         },
         :payloads => {
             'yarnconfigci' => {
                 'description' => 'hadoop yarn configurations',
                 'definition' => '{
                     "returnObject": false,
                     "returnRelation": false,
                     "relationName": "base.RealizedAs",
                     "direction": "to",
                     "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                     "relations": [{
                         "returnObject": true,
                         "returnRelation": false,
                         "relationName": "manifest.DependsOn",
                         "direction": "from",
                         "targetClassName": "manifest.oneops.1.Hadoop-yarn-config-v1"
                     }]
                 }'
             },
             'allFqdn' => {
                 'description' => 'All Fqdns',
                 'definition' => '{
                     "returnObject": false,
                     "returnRelation": false,
                     "relationName": "base.RealizedAs",
                     "direction": "to",
                     "targetClassName": "manifest.oneops.1.Hadoop-yarn-v1",
                     "relations": [{
                         "returnObject": false,
                         "returnRelation": false,
                         "relationName": "manifest.Requires",
                         "direction": "To",
                         "targetClassName": "manifest.Platform",
                         "relations": [{
                             "returnObject": false,
                             "returnRelation": false,
                             "relationName": "manifest.Requires",
                             "direction": "from",
                             "targetClassName": "manifest.oneops.1.Fqdn",
                             "relations": [{
                                 "returnObject": true,
                                 "returnRelation": false,
                                 "relationName": "base.RealizedAs",
                                 "direction": "from",
                                 "targetClassName": "bom.oneops.1.Fqdn"
                             }]
                         }]
                     }]
                 }'
             }
         }

resource 'spark-client',
         :cookbook   => spark_cookbook,
#         :source => Chef::Config[:register],
         :design     => true,
         :attributes => {
           "is_client_only" => 'true',
           "use_yarn" => 'true',
           "spark_config" => '{
                               "spark.serializer": "org.apache.spark.serializer.KryoSerializer",
                               "spark.driver.port": "4000",
                               "spark.shuffle.service.enabled": "true",
                               "spark.dynamicAllocation.enabled": "true"
                              }'
         },
         :requires   => {
           :constraint => '1..1',
           :services => '*maven',
           :help       => 'Spark Client'
         },
         :monitors => {

         },
         :payloads => {

         }

resource "spark-cassandra",
         :cookbook => "oneops.1.spark-cassandra-v#{spark_version}",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :services => "dns",
             :help => "client"
         },
         :attributes => {
           "spark_version"   => 'auto'
         }

resource "hostname",
         :cookbook => "oneops.1.fqdn",
         :design => true,
         :requires => {
           :constraint => "1..1",
           :services => "dns",
           :help => "hostname dns entry"
         }

resource "volume-work",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => { "constraint" => "1..1", "services" => "compute" },
         :attributes => {
           "mount_point"   => '/work',
           "size"          => '100%FREE',
           "device"        => '',
           "fstype"        => 'ext4',
           "options"       => ''
         },
         :monitors => {
             'usage' =>  {
               'description' => 'Usage',
               'chart' => {'min'=>0,'unit'=> 'Percent used'},
               'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
               'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
               'metrics' => { 'space_used' => metric( :unit => '%', :description => 'Disk Space Percent Used'),
                              'inode_used' => metric( :unit => '%', :description => 'Disk Inode Percent Used') },
               :thresholds => {
                 'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                 'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
               }
             }
         }

# depends_on
[ { :from => 'volume-work', :to => 'os' },
  { :from => 'volume-work', :to => 'compute' },
  { :from => 'java', :to => 'os' },
  { :from => 'client-yarn', :to => 'java' },
  { :from => 'centrify', :to => 'os' }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

[ { :from => 'spark-client', :to => 'os' },
  { :from => 'spark-client', :to => 'java' },
  { :from => 'spark-client', :to => 'volume-work' },
  { :from => 'hadoop-yarn-config', :to => 'os' },
  { :from => 'daemon',    :to => 'spark-client'  }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

# DependsOn relationships that need to have changes propagated to the
# "from" component.
[ { :from => 'spark-client', :to => 'client-yarn' },
  { :from => 'client-yarn', :to => 'hadoop-yarn-config' }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :except => [ '_default' ],
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

relation 'fqdn::depends_on::compute',
         :only          => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'fqdn',
         :to_resource   => 'compute',
         :attributes    => {:flex => false, :min => 1, :max => 1}

['java', 'spark-client', 'spark-cassandra', 'volume-work', 'client-yarn', 'centrify'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

relation "spark-cassandra::depends_on::spark-client",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'spark-cassandra',
    :to_resource   => 'fqdn',
    :attributes    => { "propagate_to" => 'from' }

# override default current to 1
[ 'lb' ].each do |from|
    relation "#{from}::depends_on::compute",
        :except => [ '_default', 'single' ],
        :relation_name => 'DependsOn',
        :from_resource => from,
        :to_resource   => 'compute',
        :attributes    => { "propagate_to" => 'from', "flex" => true, "current" =>1, "min" => 1, "max" => 10}
end
