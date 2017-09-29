name             "Centrifydc-vb1"
maintainer       '@WalmartLabs'
maintainer_email 'paas@email.wal-mart.com'
license          'All rights reserved'
description      'CentrifyDC Service (Beta 1)'
long_description 'Beta 1'
version          '0.1.0'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

  
attribute 'centrify_url',
          :description => 'Location of the Centrify RPM',
          :required => 'required',
          :default => '',
          :format => {
            :help => 'URL location where the RPM is downloaded from',
            :category => '1.General',
            :order => 1
          }

attribute 'centrify_zone',
          :description => 'Default Zone Name',
          :required => 'required',
          :default => '',
          :format => {
            :help => 'Default Centrify Zone to join',
            :category => '1.General',
            :order => 2
          }

attribute 'zone_user',
          :description => 'Zone Username',
          :required => 'required',
          :default => '',
          :format => {
            :help => 'Username to use when accessing the zone',
            :category => '1.General',
            :order => 3
          }

attribute 'zone_pwd',
          :description => 'Zone Password',
          :required => 'required',
          :encrypted => true,
          :default => '',
          :format => {
            :help => 'Password to use when accessing the zone',
            :category => '1.General',
            :order => 4
          }

attribute 'ldap_container',
          :description => 'LDAP Container Name',
          :required => 'required',
          :default => '',
          :format => {
            :help => 'LDAP Container to search for users',
            :category => '1.General',
            :order => 5
          }

attribute 'domain_name',
          :description => 'Domain Name',
          :required => 'required',
          :default => '',
          :format => {
            :help => 'DNS Domain Name',
            :category => '1.General',
            :order => 6
          }

attribute 'user_dir_parent',
          :description => 'User Directory Location',
#          :required => 'required',
          :default => '',
          :format => {
            :help => 'Directory to create for user directories to be placed in.',
            :category => '1.General',
            :order => 7
          }
