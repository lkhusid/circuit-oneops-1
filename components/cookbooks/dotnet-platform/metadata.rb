name             "Dotnet-platform"
description      "Dotnet platform Services"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"


grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service', 'service.dotnet-platform' ],
  :namespace => true

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
