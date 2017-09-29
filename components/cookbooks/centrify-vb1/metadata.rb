name             'Centrify-vb1'
maintainer       '@WalmartLabs'
maintainer_email 'paas@email.wal-mart.com'
license          'All rights reserved'
description      'Centrify Component (Beta1 build)'
long_description 'Beta 1'
version          '0.1.0'

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest' ]

grouping 'bom',
  :access => "global",
  :packages => ['bom']

attribute 'centrify_zone',
          :description => 'Zone Name',
          :required => false,
          :default => '',
          :format => {
            :help => 'Name of the Centrify Zone to join. Leave blank to use default.)',
            :category => '1.General',
            :order => 1
          }

attribute 'cdc_account_name',
          :description => 'Account Name',
          :grouping => 'bom',
          :required => false,
#          :default => ' ',
          :format => {
            :help => 'Centrify Account Name',
            :category => '2.Status',
            :order => 1
          }

attribute 'cdc_short_name',
          :description => 'Pre-Win2k Name',
          :grouping => 'bom',
          :required => false,
#          :default => ' ',
          :format => {
            :help => 'Centrify Pre-Win2k short name',
            :category => '2.Status',
            :order => 2
          }

attribute 'cdc_alias',
          :description => 'Alias',
          :grouping => 'bom',
          :required => false,
#          :default => ' ',
          :format => {
            :help => 'Centrify Computer Alias',
            :category => '2.Status',
            :order => 3
          }

attribute 'domain_controller',
          :description => 'Domain Controller',
          :grouping => 'bom',
          :required => false,
#          :default => ' ',
          :format => {
            :help => 'The domain controller that Centrify is attached to.',
            :category => '2.Status',
            :order => 4
          }

# Actions
recipe "join", "Join Zone"
recipe "leave", "Leave Zone"
recipe "info", "AD Information"
