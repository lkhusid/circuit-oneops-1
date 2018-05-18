include_pack "generic_ring"

name          "mirrormaker"
description   "Mirrormaker"
type          "Platform"
category      "Other"

platform :attributes => {'autoreplace' => 'false'}

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0" , "11061 11061 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource "user-mirrormaker",
         :cookbook => "oneops.1.user",
         :design => true,
         :requires => {"constraint" => "1..1"},
         :attributes => {
             "username" => "mirrormaker",
             "description" => "Mirrormaker User",
             "home_directory" => "/mirrormaker",
             "system_account" => true,
             "sudoer" => true
         }

resource 'compute',
         :attributes => {
             "size"    => "L",
         }
         
resource "os",
  :cookbook => "oneops.1.os",
  :attributes => { 
       "ostype"  => "centos-7.2",
       "limits" => '{"nofile": 16384}',
       "sysctl"  => '{"net.ipv4.tcp_mem":"3064416 4085888 6128832", "net.ipv4.tcp_rmem":"4096 1048576 16777216", "net.ipv4.tcp_wmem":"4096 1048576 16777216", "net.core.rmem_max":"16777216", "net.core.wmem_max":"16777216", "net.core.rmem_default":"1048576", "net.core.wmem_default":"1048576", "fs.file-max":"1048576"}',
             "dhclient"  => 'true'
		}

resource "volume-mirrormaker",
         :cookbook => "oneops.1.volume",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "compute"},
         :attributes => {"mount_point" => '/mirrormaker',
                         "size" => '100%FREE',
                         "device" => '',
                         "fstype" => 'ext4',
                         "options" => ''
         },
         :monitors => {
             'usage' => {'description' => 'Usage',
                         'chart' => {'min' => 0, 'unit' => 'Percent used'},
                         'cmd' => 'check_disk_use!:::node.workorder.rfcCi.ciAttributes.mount_point:::',
                         'cmd_line' => '/opt/nagios/libexec/check_disk_use.sh $ARG1$',
                         'metrics' => {'space_used' => metric(:unit => '%', :description => 'Disk Space Percent Used'),
                                       'inode_used' => metric(:unit => '%', :description => 'Disk Inode Percent Used')},
                          :thresholds => {
                    	    'LowDiskSpace' => threshold('5m','avg','space_used',trigger('>',90,5,1),reset('<',90,5,1)),
                            'LowDiskInode' => threshold('5m','avg','inode_used',trigger('>',90,5,1),reset('<',90,5,1)),
                          },
             }
         }

resource "hostname",
  :cookbook => "oneops.1.fqdn",
  :design => true,
  :requires => {
    :constraint => "1..1",
    :services => "dns",
    :help => "optional hostname dns entry"
  }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => '*mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {
              :install_dir => "/usr/lib/jvm",
              :jrejdk => "jdk",
              :binpath => "",
              :version => "8",
              :sysdefault => "true",
              :flavor => "oracle"
          }
         

resource "mirrormaker",
         :cookbook => "oneops.1.mirrormaker",
         :design => true,
         :requires => {"constraint" => "1..1", "services" => "mirror"},
         :attributes => {
         },
         :monitors => {
             'mirrormakerprocess' => {:description => 'MirrormakerProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!mirrormaker!true!kafka.tools.MirrorMaker',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'MirrormakerProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
                           }
             },
             'mirrormakerlag' =>  {'description' => 'MirrorMaker Lag Monitoring',
                 :enable => 'false',
		 'chart' => {'min'=>0,'unit'=> 'Number'},
                 'cmd' => 'check_mirrormaker_lag',
                 'cmd_line' => '/opt/nagios/libexec/check_mirrormaker_lag.sh',
                 'metrics' => {
                     'lag' => metric(:unit => 'count', :description => 'Lag between source and target'),
                 },
                 :thresholds => {
                     'MirrorMakerLagWarning' => threshold('1m','avg','lag',trigger('>',3000000,1,1),reset('<',3000000,1,1)),
                     'MirrorMakerLagCritical' => threshold('1m','avg','lag',trigger('>',5000000,1,1),reset('<',5000000,1,1)),
                 },
             },
             'mirrormakerlog' => {:description => 'MirrormakerLog',
		 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_logfiles!logmirrormaker!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                 :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                 :cmd_options => {
                     'logfile' => '/mirrormaker/log/mirrormaker.log',
                     'warningpattern' => 'WARN',
                     'criticalpattern' => 'ERROR'
                 },
                 :metrics => {
                     'logmirrormaker_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                     'logmirrormaker_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                     'logmirrormaker_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                     'logmirrormaker_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                     'CriticalMirrormakerLogException' => threshold('15m', 'avg', 'logmirrormaker_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1)),
                 }
             }
          }


resource "artifact",
  :cookbook => "oneops.1.artifact",
  :design => true,
  :requires => { "constraint" => "0..*" },
  :attributes => {

  }

resource "keystore",
  :cookbook => "oneops.1.keystore",
  :design => true,
  :requires => {"constraint" => "0..1"},
  :attributes => {
     "keystore_filename" => "/var/lib/certs/mirrormaker.keystore.jks"
  }

resource "client-certs-download",
         :cookbook => "oneops.1.download",
         :design => true,
         :requires => {
             :constraint => "0..*",
         },
         :attributes => {
             :source => '',
             :basic_auth_user => "",
             :basic_auth_password => "",
             :path => '',
             :post_download_exec_cmd => ''
         }
resource "volume",
  :cookbook => "oneops.1.volume",
  :requires => { "constraint" => "0..1", "services" => "compute" }
  
# depends_on
[
 {:from => 'client-certs-download', :to => 'user-mirrormaker'},
 {:from => 'artifact',      :to => 'mirrormaker'},
 {:from => 'mirrormaker', :to => 'certificate'},
 {:from => 'mirrormaker', :to => 'keystore'},
 {:from => 'keystore', :to => 'certificate'},
 {:from => 'mirrormaker', :to => 'user-mirrormaker'},
 {:from => 'user-mirrormaker', :to => 'volume-mirrormaker'},
 {:from => 'volume-mirrormaker', :to => 'os'},
 {:from => 'java', :to => 'os'},
 {:from => 'os', :to => 'compute'}
].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
           :relation_name => 'DependsOn',
           :from_resource => link[:from],
           :to_resource => link[:to],
           :attributes => {"flex" => false, "min" => 1, "max" => 1}
end

# propagation rule for replace
[ 'hostname' ].each do |from|
  relation "#{from}::depends_on::compute",
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }
end

# DependsOn
[ 'fqdn' ].each do |from|
  relation "#{from}::depends_on::ring",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => from,
    :to_resource   => 'ring',
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "ring::depends_on::mirrormaker",
    :except => [ '_default', 'single' ],
    :relation_name => 'DependsOn',
    :from_resource => 'ring',
    :to_resource   => 'mirrormaker',
    :attributes    => { "flex" => true, "min" => 3, "max" => 10 }

# managed_via
[ 'mirrormaker'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

# managed_via
['user-mirrormaker', 'artifact', 'mirrormaker', 'java', 'library','volume-mirrormaker', 'keystore', 'client-certs-download'].each do |from|
  relation "#{from}::managed_via::compute",
           :except => ['_default'],
           :relation_name => 'ManagedVia',
           :from_resource => from,
           :to_resource => 'compute',
           :attributes => {}
end
