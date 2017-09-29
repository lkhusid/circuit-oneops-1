include_pack "genericlb"

name "custom-centrify-vb1"
description "Custom with Centrify (Beta 1)"
type "Platform"
category "Other"

platform :attributes => {'autoreplace' => 'false'}

# Define resources for a standalone Spark client
resource 'secgroup',
         :cookbook   => 'oneops.1.secgroup',
         :design     => true,
         :attributes => {
           # Port configuration:
           #
           #    -1:  Ping
           #    22:  SSH
           # 60000:  For mosh
           #
           "inbound" => '[
               "-1 -1 icmp 0.0.0.0/0",
               "22 22 tcp 0.0.0.0/0",
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

resource "centrify",
         :cookbook => "oneops.1.centrify-vb1",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :services => "centrify",
             :help => "Centrify AD authentication for Linux"
         },
         :attributes => { }

# depends_on
[ { :from => 'java', :to => 'os' },
  { :from => 'centrify', :to => 'os' }
 ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation 'fqdn::depends_on::compute',
         :only          => ['_default', 'single'],
         :relation_name => 'DependsOn',
         :from_resource => 'fqdn',
         :to_resource   => 'compute',
         :attributes    => {:flex => false, :min => 1, :max => 1}

['java', 'centrify'].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end

# override default current to 1
[ 'lb' ].each do |from|
    relation "#{from}::depends_on::compute",
        :except => [ '_default', 'single' ],
        :relation_name => 'DependsOn',
        :from_resource => from,
        :to_resource   => 'compute',
        :attributes    => { "propagate_to" => 'from', "flex" => true, "current" =>1, "min" => 1, "max" => 10}
end
