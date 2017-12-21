name             'Nugetpackage'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook installs nuget packages'
version          '0.1.0'

supports 'windows'

grouping 'default',
  :access   => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]

attribute 'repository_url',
  :description => "Repository URL",
  :required    => "required",
  :format      => {
    :help      => 'Base URL of the repository, Ex: https://www.nuget.org/api/v2/',
    :category  => '1.General',
    :order     => 1
  }

attribute 'physical_path',
  :description => 'Application Directory',
  :default     => '',
  :required    => 'required',
  :format      => {
    :help      => 'The application directory where the package will be installed, Default value is set to e:\apps',
    :category  => '1.General',
    :order     => 2
  }

attribute 'install_dir',
  :description => 'Install Directory',
  :default     => '',
  :required    => 'required',
  :format      => {
    :help      => 'The physical path on disk where the package will be deployed, Default value is set to e:\platform_deployment',
    :category  => '1.General',
    :order     => 3
  }

attribute 'nuget_package_details',
  :description => "Package Details",
  :data_type   => "hash",
  :default     => '{}',
  :format      => {
    :help      => 'Add nuget package details. Format: <nuget package name> = <nuget package version>',
    :category  => '2.Nuget Package Details',
    :order     => 1
  }
