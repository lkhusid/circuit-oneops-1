name             'Azureobjectstore'
maintainer       '@WalmartLabs'
maintainer_email 'umullangi@walmartlabs.com'
license          'All rights reserved'
description      'Installs/Configures azure objectstore service'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
grouping 'default',
         :access => 'global',
         :packages => %w[base service.filestore mgmt.cloud.service cloud.service cloud.zone.service],
         :namespace => true

attribute 'tenant_id',
  :description => 'Tenant ID',
  :required => 'required',
  :format => {
    :help => 'Tenant ID for Azure',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'proxy',
  :description => 'API Proxy',
  :required => 'optional',
  :format => {
    :help => 'API proxy is used to address timeout issues when making direct API calls to Azure',
    :category => '1.Authentication',
    :order => 2
  }
