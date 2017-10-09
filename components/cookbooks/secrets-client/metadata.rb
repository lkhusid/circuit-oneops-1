name                'Secrets-client'
description         'Installs/Configures Secrets client'
version             '0.1'
maintainer          'OneOps'
maintainer_email    'support@oneops.com'
license             'Apache License, Version 2.0'

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'user',
          :description => 'User',
          :required => 'required',
          :default => 'root',
          :format => {
              :important => true,
              :help => 'User that can access the secrets under /secrets mount',
              :category => '1.General',
              :order => 1
          }

attribute 'group',
          :description => 'Group',
          :required => 'required',
          :default => 'root',
          :format => {
              :important => true,
              :help => 'User group that can access the secrets under /secrets mount',
              :category => '1.General',
              :order => 2
          }

recipe 'stop', 'Stop'
recipe 'restart', 'Restart'

