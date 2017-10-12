name             'Taskscheduler'
maintainer       'Oneops'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
description      'Installs/Configures taskscheduler'
version          '0.1.0'

supports 'windows'
depends 'artifact'
depends 'windows-utils'

grouping 'default',
  :access   => 'global',
  :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

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

attribute 'task_name',
  :description => 'Name',
  :required    => 'required',
  :format      => {
    :help      => 'Name of the task to create',
    :category  => '2.General',
    :order     => 1
  }

attribute 'task_description',
  :description => 'Description',
  :format      => {
    :help      => 'Description of the task',
    :category  => '2.General',
    :order     => 2
  }

attribute 'path',
  :description => 'Executable Path',
  :required    => 'required',
  :format      => {
    :help      => 'Path to the program/script to be scheduled. Path should be relative to the package installation directory, ex bin\test.exe, myapp.exe',
    :category  => '3.Actions',
    :order     => 1
  }

attribute 'physical_path',
  :description => 'Application directory',
  :required    => 'required',
  :format      => {
    :help      => 'Application directory where the package is to be installed. Ex e:\apps',
    :category  => '3.Actions',
    :pattern   => '^((?:[${}a-zA-Z]:){0,1}(?:[\\\/$][${}a-zA-Z0-9]+(?:_[${}a-zA-Z0-9]+)*(?:-[${}a-zA-Z0-9]+)*)+)$',
    :order     => 2
  }

attribute 'arguments',
  :description => 'Arguments',
  :format      => {
    :help      => 'Arguments to be supplied to the program/script',
    :category  => '3.Actions',
    :order     => 3
  }

attribute 'working_directory',
  :description => 'Start in',
  :format      => {
    :help      => 'Path to the directory from where the program/script is to be run',
    :category  => '3.Actions',
    :order     => 4
  }

attribute 'username',
  :description => 'Username',
  :required    => 'required',
  :format      => {
    :help      => 'User under which the program/script is to be run',
    :category  => '4.Authentication',
    :order     => 1
  }



attribute 'password',
  :description => 'Password',
  :required    => 'required',
  :encrypted   => true,
  :format      => {
    :help      => 'Password of the user',
    :category  => '4.Authentication',
    :order     => 2
  }

attribute 'frequency',
  :description => 'Frequency',
  :required    => 'required',
  :format      => {
    :help      => 'Frequency of the program/script',
    :category  => '5.Triggers',
    :order     => 1,
    :form      => { 'field' => 'select', 'options_for_select' => [['once', 'once'], ['daily', 'daily'], ['weekly', 'weekly']] }
  }

attribute 'days_interval',
  :description => 'Days Frequency',
  :default => '1',
  :format => {
    :help => 'Frequency of days to run the task',
    :category => '5.Triggers',
    :order => 2,
    :filter => {'all' => {'visible' => 'frequency:eq:daily'}}
  }

attribute 'days_of_week',
  :description => 'Days Of Week',
  :format => {
    :help => 'Days of Week to run the task',
    :category => '5.Triggers',
    :order => 3,
    :filter => {'all' => {'visible' => 'frequency:eq:weekly'}},
    :form      => { 'field' => 'select',
                    'options_for_select' => [['Sunday', 'Sunday'], ['Monday', 'Monday'], ['Tuesday', 'Tuesday'],
                                             ['Wednesday', 'Wednesday'], ['Thursday', 'Thursday'], ['Friday', 'Friday'],
                                             ['Saturday', 'Saturday']]
                  }
  }

attribute 'weeks_interval',
  :description => 'Weeks Frequency',
  :default => '1',
  :format => {
    :help => 'Frequency of Weeks to run the task',
    :category => '5.Triggers',
    :order => 4,
    :filter => {'all' => {'visible' => 'frequency:eq:weekly'}}
  }


attribute 'start_day',
  :description => 'Start Day',
  :required    => 'required',
  :format      => {
    :help      => 'Start day of the task, Format yyyy-mm-dd, ex 2016-12-26, 2016-05-15',
    :category  => '5.Triggers',
    :pattern   => '^\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])$',
    :order     => 5
  }

attribute 'start_time',
  :description => 'Start Time',
  :required    => 'required',
  :format      => {
    :help      => 'Start time of the task, Format HH:MM:SS, ex 23:30:00, 07:45:00',
    :category  => '5.Triggers',
    :pattern   => '^([0-1]\d|2[0-3]):([0-5]\d):([0-5]\d)$',
    :order     => 6
  }

attribute 'execution_time_limit',
  :description => 'Execution Time Limit',
  :required    => 'required',
  :format      => {
    :help      => 'Stop the task if it runs longer than given time ex 1 hour, 2 hour',
    :category  => '6.Settings',
    :order     => 1,
    :form      => { 'field' => 'select', 'options_for_select' => [['3 days', 'P3D'], ['1 hour', 'PT1H'], ['2 hours', 'PT2H'], ['4 hours', 'PT4H'], ['8 hours', 'PT8H'], ['12 hours', 'PT12H'], ['1 day', 'P1D']] }
  }



recipe 'run_task', 'Run Task'
recipe 'end_task', 'End Task'
recipe 'restart_task', 'Restart Task'
recipe 'delete', 'Delete Task'
