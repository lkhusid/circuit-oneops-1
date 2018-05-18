name             'Objectstore'
maintainer       '@walmartlabs'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures object-store'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'client_id',
  :description => 'Client ID',
  :required => 'optional',
  :format => {
    :help => 'Client ID for Azure',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'storage_id',
  :description => 'Storage ID',
  :required => 'optional',
  :format => {
    :help => 'Storage Account ID for Azure',
    :category => '1.Authentication',
    :order => 2
  }
