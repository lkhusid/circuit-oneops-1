name             'Iis-webapp'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook creates/configures iis website'
version          '0.1.0'

supports 'windows'

depends 'iis-website'
depends 'iis'
depends 'artifact'

grouping 'default',
  :access   => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]


attribute 'package_name',
  :description => "Package Name",
  :required    => "required",
  :format      =>   {
    :help      => 'Name of the package in the repository',
    :category  => '1.Nuget Package',
    :order     => 1
  }

attribute 'repository_url',
  :description => "Repository URL",
  :required    => "required",
  :format      => {
    :help      => 'Base URL of the repository, Ex: https://www.nuget.org/api/v2/',
    :category  => '1.Nuget Package',
    :order     => 2
  }

attribute 'version',
  :description => "Version",
  :required    => "required",
  :format      => {
    :help      => 'Version of the package being deployed',
    :category  => '1.Nuget Package',
    :order     => 3
  }


attribute 'new_app_pool_required',
  :description => 'New app pool required',
  :default     => 'false',
  :format      => {
    :help      => 'Specifies whether new application pool is to be created for the web application.',
    :category  => '2.IIS Application Pool',
    :form      => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'runtime_version',
:description => '.Net CLR version',
:required    => 'required',
:default     => 'v4.0',
:format      => {
  :help      => 'The version of .Net CLR runtime that the application pool will use',
  :category  => '2.IIS Application Pool',
  :order     => 2,
  :filter    => {'all' => {'visible' => 'new_app_pool_required:eq:true'}},
  :form      => {
                  'field' => 'select',
                  'options_for_select' => [['v2.0', 'v2.0'],
                                           ['v4.0', 'v4.0'],
                                           ['No Managed Code', 'NoManagedCode']]
                }
}

attribute 'identity_type',
  :description => 'Identity type',
  :required    => 'required',
  :default     => 'ApplicationPoolIdentity',
  :format      => {
  :help        => 'Select the built-in account which application pool will use',
    :category  => '2.IIS Application Pool',
    :order     => 3,
    :filter    => {'all' => {'visible' => 'new_app_pool_required:eq:true'}},
    :form      => { 'field' => 'select',
                    'options_for_select' => [
                      ['Application Pool Identity', 'ApplicationPoolIdentity'],
                      ['Network Service', 'NetworkService'],
                      ['Local Service', 'LocalService'],
                      ['Specific User', 'SpecificUser']
                    ]
                  }
  }

attribute 'process_model_user_name',
  :description => 'Username',
  :default     => '',
  :format      => {
  :help        => 'The user name of the account which application pool will use',
    :category  => '2.IIS Application Pool',
    :order     => 4,
    :filter    => {'all' => {'visible' => 'identity_type:eq:SpecificUser'}}
  }

attribute 'process_model_password',
  :description => 'Password',
  :encrypted   => true,
  :default     => '',
  :format      => {
  :help        => 'Password for the user account',
    :category  => '2.IIS Application Pool',
    :order     => 5,
    :filter    => {'all' => {'visible' => 'identity_type:eq:SpecificUser'}}
  }

attribute 'application_path',
  :description => "Application Path",
  :required    => "required",
  :format      => {
    :help      => 'Relative path from the parent IIS Web Site. Eg: /sales',
    :editable  => 'false',
    :important => 'true',
    :category  => '3.Web Application',
    :order     => 1
  }

attribute 'physical_path',
  :description => "Physical Path",
  :required    => "required",
  :format      => {
    :help      => 'The physical path of the application.',
    :category  => '3.Web Application',
    :order     => 2
  }
