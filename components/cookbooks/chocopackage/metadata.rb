name             'Chocopackage'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook installs applications using chocolatey packages'
version          '0.1.0'

supports 'windows'

grouping 'default',
  :access   => "global",
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'chocolatey_package_source',
  :description => 'Package url',
  :default     => 'https://chocolatey.org/api/v2/',
  :required    => "required",
  :format      => {
    :help      => 'Chocolatey package url',
    :category  => '1.Chocolatey Package Source',
    :order     => 1
  }

attribute 'chocolatey_package_details',
  :description => "Package details",
  :data_type   => "hash",
  :default     => '{}',
  :format      => {
    :help      => 'Add chocolatey package details. Format: <chocolatey package name> = <chocolatey package version>',
    :category  => '2.Chocolatey package details',
    :order     => 1
  }
