name             'Iis-website'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'This cookbook creates/configures iis website'
version          '0.1.0'

supports 'windows'
depends 'iis'
depends 'artifact'
depends 'taskscheduler'



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

attribute 'physical_path',
  :description => 'Web Site Physical Path',
  :required    => 'required',
  :format      => {
    :help      => 'The physical path on disk this Web Site will point to, Default value is set to e:\apps',
    :category  => '2.IIS Web site',
    :order     => 1
  }

attribute 'static_mime_types',
  :description => 'Mime type(s)',
  :data_type   => 'hash',
  :default     => '{}',
  :format      => {
    :help      => 'Adds MIME type(s) to the collection of static content types. Eg: .tab = application/xml',
    :category  => '2.IIS Web site',
    :order     => 2
  }

attribute 'binding_type',
  :description => 'Binding Type',
  :default     => 'http',
  :required    => 'required',
  :format      => {
    :help      => 'Select HTTP/HTTPS bindings that should be added to the IIS Web Site',
    :category  => '2.IIS Web site',
    :order     => 3,
    :form      => { 'field' => 'select',
                    'options_for_select' => [
                      ['http', 'http'],
                      ['https', 'https']
                    ]
                  }
  }

attribute 'binding_port',
  :description => 'Binding Port',
  :default     => '80',
  :required    => 'required',
  :format      => {
    :help      => 'IIS binding port',
    :category  => '2.IIS Web site',
    :order     => 4
  }

attribute 'windows_authentication',
  :description => 'Windows authentication',
  :default     => 'false',
  :format      => {
    :help      => 'Enable windows authentication',
    :category  => '2.IIS Web site',
    :form     => {'field' => 'checkbox'},
    :order     => 5
  }

attribute 'anonymous_authentication',
  :description => 'Anonymous authentication',
  :default     => 'true',
  :format      => {
    :help      => 'Enable anonymous authentication',
    :category  => '2.IIS Web site',
    :form     => {'field' => 'checkbox'},
    :order     => 6
  }

attribute 'iis_iusrs_group_service_accounts',
  :description => 'Service accounts (iis_iusrs)',
  :data_type   => 'array',
  :default     => '[]',
  :format      => {
    :help      => 'Add Service Accounts to the IIS_IUSRS Group',
    :category  => '2.IIS Web site',
    :order     => 7
  }

attribute 'enabled',
  :description => 'Enable IIS Logging',
  :default     => 'true',
  :format      => {
    :help      => 'Specifies whether logging is enabled (true) or disabled (false) for a site.',
    :category  => '3.IIS Logging',
    :form     => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'log_file_directory',
  :description => 'Log file directory',
  :format      => {
    :help      => 'Specifies the logging directory, where the log file and logging-related support files are stored.',
    :category  => '3.IIS Logging',
    :filter    => {'all' => {'visible' => 'enabled:eq:true'}},
    :order     => 2
  }

attribute 'logformat',
  :description => 'Log file format',
  :default     => 'W3C',
  :format      => {
    :help      => 'Specifies the log file format.',
    :category  => '3.IIS Logging',
    :order     => 3,
    :filter    => {'all' => {'visible' => 'enabled:eq:true'}},
    :form      => { 'field' => 'select',
                    'options_for_select' => [
                      ['W3C', 'W3C'],
                      ['NCSA', 'NCSA'],
                      ['IIS','IIS']
                    ]
                  }
}

attribute 'period',
  :description => 'Period',
  :default     => 'Daily',
  :format      => {
    :help      => 'Specifies how often IIS creates a new log file',
    :category  => '3.IIS Logging',
    :order     => 4,
    :filter    => {'all' => {'visible' => 'enabled:eq:true'}},
    :form      => { 'field' => 'select',
                    'options_for_select' => [
                      ['Daily', 'Daily'],
                      ['Hourly', 'Hourly'],
                      ['MaxSize', 'MaxSize'],
                      ['Monthly', 'Monthly'],
                      ['Weekly', 'Weekly']
                    ]
                  }
}

attribute 'logtargetw3c',
  :description => 'Log Event Destination',
  :default     => '1',
  :format      => {
    :help      => 'Specifies whether IIS will use Event Tracing for Windows (ETW) and/or file logging for processing logged IIS events',
    :category  => '3.IIS Logging',
    :order     => 2,
    :filter    => {'all' => {'visible' => 'enabled:eq:true'}},
    :form      => { 'field' => 'select',
                    'options_for_select' => [
                      ['Log File only', 1],
                      ['ETW only', 2],
                      ['Both log file and ETW event', 3]
                    ]
                  }
  }

attribute 'runtime_version',
:description => '.Net CLR version',
:required    => 'required',
:default     => 'v4.0',
:format      => {
  :help      => 'The version of .Net CLR runtime that the application pool will use',
  :category  => '4.IIS Application Pool',
  :order     => 1,
  :form      => { 'field' => 'select',
                  'options_for_select' => [['v2.0', 'v2.0'], ['v4.0', 'v4.0']]
                }
}

attribute 'identity_type',
  :description => 'Identity type',
  :required    => 'required',
  :default     => 'ApplicationPoolIdentity',
  :format      => {
  :help        => 'Select the built-in account which application pool will use',
    :category  => '4.IIS Application Pool',
    :order     => 2,
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
    :category  => '4.IIS Application Pool',
    :order     => 3,
    :filter    => {'all' => {'visible' => 'identity_type:eq:SpecificUser'}}
  }

attribute 'process_model_password',
  :description => 'Password',
  :encrypted   => true,
  :default     => '',
  :format      => {
  :help        => 'Password for the user account',
    :category  => '4.IIS Application Pool',
    :order     => 4,
    :filter    => {'all' => {'visible' => 'identity_type:eq:SpecificUser'}}
  }


attribute 'enable_static_compression',
  :description => 'Enable static compression',
  :default     => 'true',
  :format      => {
    :help      => 'Specifies whether static compression is enabled for URLs.',
    :category  => '5.IIS Static Compression',
    :form      => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'sc_level',
  :description => 'Compression level',
  :default     => '7',
  :required    => 'required',
  :format      => {
    :help      => 'Compression level - from 0 (none) to 10 (maximum)',
    :category  => '5.IIS Static Compression',
    :order     => 2,
    :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
    :form      => { 'field' => 'select',
                    'options_for_select' => [['0', '0'], ['1', '1'], ['2', '2'],
                                             ['3', '3'], ['4', '4'], ['5', '5'],
                                             ['6', '6'], ['7', '7'], ['8', '8'],
                                             ['9', '9'], ['10', '10']]
                  }
  }

attribute 'sc_mime_types',
  :description => 'Mime type(s)',
  :default     => '{
    "text/*":"true",
    "message/*":"true",
    "application/x-javascript":"true",
    "application/atom+xml":"true",
    "application/json":"true",
    "application/xml":"true",
    "*/*":"false"
  }',
  :data_type   => 'hash',
  :format      => {
    :help      => 'Which mime-types will be / will not be compressed',
    :category  => '5.IIS Static Compression',
    :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
    :order     => 3
  }

attribute 'sc_cpu_usage_to_disable',
  :description => 'CPU usage disable',
  :default     => '90',
  :required    => 'required',
    :format      => {
      :help      => 'The percentage of CPU utilization (0-100) above which compression is disabled',
      :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
      :category  => '5.IIS Static Compression',
      :order     => 4
  }

attribute 'sc_cpu_usage_to_reenable',
  :description => 'CPU usage re-enable',
  :default     => '50',
  :required    => 'required',
    :format      => {
      :help      => 'The percentage of CPU utilization (0-100) below which compression is re-enabled after disable due to excess usage',
      :category  => '5.IIS Static Compression',
      :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
      :order     => 5
  }

attribute 'compression_max_disk_usage',
  :description => 'Maximum disk usage',
  :default     => '100',
  :required    => 'required',
  :format      => {
    :help      => 'Disk space limit (in megabytes), that compressed files can occupy',
    :category  => '5.IIS Static Compression',
    :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
    :order     => 5
  }

attribute 'compresion_min_file_size',
  :description => 'Minimum file size to compression',
  :required    => 'required',
  :default     => '2400',
  :format      => {
    :help      => 'The minimum file size (in bytes) for a file to be compressed',
    :category  => '5.IIS Static Compression',
    :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
    :order     => 5
  }

attribute 'sc_file_directory',
  :description => 'Compression file directory',
  :required    => 'required',
    :format      => {
      :help      => 'Location of the directory to store compressed files',
      :category  => '5.IIS Static Compression',
      :filter    => {'all' => {'visible' => 'enable_static_compression:eq:true'}},
      :order     => 6
    }

attribute 'enable_dynamic_compression',
  :description => 'Enable dynamic compression',
  :default     => 'true',
  :format      => {
    :help      => 'Specifies whether dynamic compression is enabled for URLs',
    :category  => '6.IIS Dynamic Compression',
    :form      => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'dc_level',
  :description => 'Compression level',
  :default     => '0',
  :required    => 'required',
  :format      => {
    :help      => 'Compression level - from 0 (none) to 10 (maximum)',
    :category  => '6.IIS Dynamic Compression',
    :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
    :order     => 2,
    :form      => { 'field' => 'select',
                    'options_for_select' => [['0', '0'], ['1', '1'], ['2', '2'],
                                             ['3', '3'], ['4', '4'], ['5', '5'],
                                             ['6', '6'], ['7', '7'], ['8', '8'],
                                             ['9', '9'], ['10', '10']]
                  }
  }

attribute 'dc_mime_types',
  :description => 'Mime type(s)',
  :default     => '{
    "text/*":"true",
    "message/*":"true",
    "application/x-javascript":"true",
    "application/xml":"true",
    "*/*":"false"
  }',
  :data_type   => 'hash',
  :format      => {
    :help      => 'Which mime-types will be / will not be compressed',
    :category  => '6.IIS Dynamic Compression',
    :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
    :order     => 3
  }

attribute 'dc_cpu_usage_to_disable',
  :description => 'CPU usage disable',
  :default     => '90',
  :required    => 'required',
    :format      => {
      :help      => 'The percentage of CPU utilization (0-100) above which compression is disabled',
      :category  => '6.IIS Dynamic Compression',
      :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
      :order     => 4
    }

attribute 'dc_cpu_usage_to_reenable',
  :description => 'CPU usage re-enable',
  :default     => '50',
  :required    => 'required',
    :format      => {
      :help      => 'The percentage of CPU utilization (0-100) below which compression is re-enabled after disable due to excess usage',
      :category  => '6.IIS Dynamic Compression',
      :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
      :order     => 5
    }

attribute 'url_compression_dc_before_cache',
  :description => 'Dynamic compression before cache',
  :default     => 'false',
  :format      => {
    :help      => 'Specifies whether the currently available response is dynamically compressed before it is put into the output cache.',
    :category  => '6.IIS Dynamic Compression',
    :form      => {'field' => 'checkbox'},
    :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
    :order     => 6
  }

attribute 'dc_file_directory',
  :description => 'Compression file directory',
  :required    => 'required',
    :format      => {
      :help      => 'Location of the directory to store compressed files',
      :category  => '6.IIS Dynamic Compression',
      :filter    => {'all' => {'visible' => 'enable_dynamic_compression:eq:true'}},
      :order     => 7
    }

attribute 'session_state_cookieless',
  :description => 'Cookieless',
  :default     => 'UseCookies',
  :format      => {
    :help      => 'Specifies how cookies are used for a Web application.',
    :category  => '7.Session State',
    :form        => { 'field' => 'select',
                    'options_for_select' => [['Use URI', 'UseURI'], ['Use Cookies', 'UseCookies'],
                                             ['Auto Detect', 'AutoDetect'], ['Use Device Profile', 'UseDeviceProfile']]
                    },
    :order     => 1
  }

attribute 'session_state_cookie_name',
  :description => 'Cookie name',
  :default     => 'ASP.NET_SessionId',
  :format      => {
    :help      => 'Specifies the name of the cookie that stores the session identifier.',
    :category  => '7.Session State',
    :order     => 2
  }

attribute 'session_time_out',
  :description => 'Time out',
  :default     => '20',
  :format      => {
    :help      => 'Specifies the number of minutes a session can be idle before it is abandoned.',
    :category  => '7.Session State',
    :order     => 3
  }

attribute 'requestfiltering_allow_double_escaping',
  :description => 'Allow double escaping',
  :default     => 'false',
  :format      => {
    :help      => 'If set to false, request filtering will deny the request if characters that have been escaped twice are present in URLs.',
    :category  => '8.Request filtering',
    :form      => {'field' => 'checkbox'},
    :order     => 1
  }

attribute 'requestfiltering_allow_high_bit_characters',
  :description => 'Allow high bit characters',
  :default     => 'false',
  :format      => {
    :help      => 'If set to true, request filtering will allow non-ASCII characters in URLs.',
    :category  => '8.Request filtering',
    :form      => {'field' => 'checkbox'},
    :order     => 2
  }

attribute 'requestfiltering_verbs',
  :description => 'Verbs',
  :default     => '{ "TRACE": "false" }',
  :data_type   => 'hash',
  :format      => {
    :help      => 'Specifies which HTTP verbs are allowed or denied to limit types of requests sent to the Web server.',
    :category  => '8.Request filtering',
    :order     => 3
  }

attribute 'requestfiltering_max_allowed_content_length',
  :description => 'Maximum allowed content length',
  :default     => '30000000',
  :format      => {
    :help      => 'Specifies the maximum length of content in a request, in bytes.',
    :category  => '8.Request filtering',
    :order     => 4
  }

attribute 'requestfiltering_max_url',
  :description => 'Maximum url length',
  :default     => '4096',
  :format      => {
    :help      => 'Specifies the maximum length of the URL, in bytes.',
    :category  => '8.Request filtering',
    :order     => 5
  }

attribute 'requestfiltering_max_query_string',
  :description => 'Maximum query string length',
  :default     => '2048',
  :format      => {
    :help      => 'Specifies the maximum length of the query string, in bytes.',
    :category  => '8.Request filtering',
    :order     => 6
  }

attribute 'requestfiltering_file_extension_allow_unlisted',
  :description => 'File extension allow unlisted',
  :default     => 'true',
  :format      => {
    :help      => 'Specifies whether the Web server should process files that have unlisted file name extensions.',
    :category  => '8.Request filtering',
    :form      => {'field' => 'checkbox'},
    :order     => 7
  }

attribute 'logs_retention_days',
  :description => 'Logs retention in days',
  :default     => '7',
  :required    => 'required',
  :format      => {
    :help      => 'Specify the number of days for IIS logs retention, Ex: 7',
    :category  => '9.IIS logs clean up',
    :order     => 1
  }

attribute 'logs_cleanup_up_time',
  :description => 'Logs cleanup time',
  :default     => '02:00:00',
  :required    => 'required',
  :format      => {
    :help      => 'Specify the time when clean up should trigger, Format HH:MM:SS, ex 23:30:00, 07:45:00',
    :category  => '9.IIS logs clean up',
    :pattern   => '^([0-1]\d|2[0-3]):([0-5]\d):([0-5]\d)$',
    :order     => 2
  }

recipe 'app_pool_recycle', 'Recycle application pool'
recipe 'iis_reset', 'Restart IIS'
