name             'Dotnetframework'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook install .net frameworks'
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
    :help      => 'Chocolatey package url for the .net framework chocolatey packages',
    :category  => '1.Chocolatey Package Source',
    :order     => 1
  }

attribute 'dotnet_version_package_name',
  :description => ".Net Framework version",
  :data_type   => "hash",
  :default     => '{ ".Net 4.6":"dotnet4.6" }',
  :format      => {
    :help      => 'Add .net framework version. Format: .Net <version> = <chocolatey package name>',
    :category  => '2.Framework version',
    :filter    => {'all' => {'visible' => 'install_dotnetcore:eq:false'}},
    :order     => 1
  }


attribute 'install_dotnetcore',
  :description => 'Install dotnet core',
  :default     => "false",
  :format      => {
    :help      => 'Enable to install dotnet core',
    :category  => '3.Dotnet Core Details',
    :form      => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'dotnet_core_package_name',
  :description => 'Dotnet Core',
  :default     => 'dotnetcore-runtime',
  :required    => 'required',
  :format      => {
    :help      => 'Select dotnet core runtime or sdk',
    :category  => '3.Dotnet Core Details',
    :order     => 2,
    :filter    => {'all' => {'visible' => 'install_dotnetcore:eq:true'}},
    :form      => { 'field' => 'select',
                    'options_for_select' => [['dotnetcore-runtime', 'dotnetcore-runtime'],
                                             ['dotnetcore-sdk', 'dotnetcore-sdk'],
                                             ['dotnetcore-windowshosting', 'dotnetcore-windowshosting'],]
                  }
  }

attribute 'dotnet_core_version',
  :description => "Version",
  :default     => '["2.0.3"]',
  :data_type   => 'array',
  :format      => {
    :help      => 'Add dotnet core runtime chocolatey package version.',
    :category  => '3.Dotnet Core Details',
    :filter    => {'all' => {'visible' => 'install_dotnetcore:eq:true'}},
    :order     => 3
  }
