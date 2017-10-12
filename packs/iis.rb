include_pack "genericlb"

name "iis"
description "Internet Information Services(IIS)"
type "Platform"
category "Web Application"

environment "single", {}
environment "redundant", {}

platform :attributes => {'autocomply' => 'true'}

variable "platform_deployment",
  :description => 'Downloads the nuget packages',
  :value       => 'e:\platform_deployment'

variable "app_directory",
  :description => 'Application directory',
  :value       => 'e:\apps'

variable "nuget_exe",
  :description => 'Nuget exe path',
  :value       => 'C:\ProgramData\chocolatey\lib\NuGet.CommandLine\tools\NuGet.exe'

variable "log_directory",
  :description => 'Log directory',
  :value       => 'e:\logs'

variable "drive_name",
  :description => 'drive name',
  :value       => 'E'

resource "compute",
  :attributes => {"size" => "M-WIN"}

resource "iis-website",
  :cookbook     => "oneops.1.iis-website",
  :design       => true,
  :requires     => {
    :constraint => "1..1",
    :help       => "Installs/Configure IIS"
  },
  :attributes   => {
    "package_name"                      => '',
    "repository_url"                    => '',
    "version"                           => 'latest',
    "physical_path"                     => '$OO_LOCAL{app_directory}',
    "log_file_directory"                => '$OO_LOCAL{log_directory}',
    "logformat"                         => 'W3C',
    "period"                            => 'Daily',
    "logtargetw3c"                      => '1',
    "dc_file_directory"                 => '$OO_LOCAL{log_directory}\\IISTemporaryCompressedFiles',
    "sc_file_directory"                 => '$OO_LOCAL{log_directory}\\IISTemporaryCompressedFiles',
    "windows_authentication"            => 'false',
    "requestfiltering_allow_high_bit_characters" => 'false'
  },
  :monitors => {
  'IISW3SVC' =>  { :description => 'W3SVC service status',
     :chart => {'min' => 0, 'unit' => ''},
     :heartbeat => false,
     :cmd => 'iis_service_status.ps1',
     :cmd_line => 'powershell.exe -file /opt/nagios/libexec/iis_service_status.ps1',
     :metrics =>  {
       'up'  => metric( :unit => '%', :description => 'Up %')
     },
     :thresholds => {
        'ProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1),'unhealthy')
     },
   },
   'AspNetCounters' =>  { :description => 'ASP.NET counters',
      :chart => {'min' => 0, 'unit' => ''},
      :heartbeat => false,
      :cmd => 'aspnet_counters.ps1',
      :cmd_line => 'powershell.exe -file /opt/nagios/libexec/aspnet_counters.ps1',
      :metrics =>  {
        'RequestCount'  => metric(:unit => '', :description => 'Indicates number of requests per second handled by the application.', :dstype => 'GAUGE'),
        'RequestsTotal'  => metric(:unit => '', :description => 'Indicates number of current requests', :dstype => 'GAUGE'),
        'TotalErrorsPerSec'  => metric(:unit => 'errors /sec', :description => 'Indicates number of errors per second.', :dstype => 'GAUGE'),
        'RequestsExecuting'  => metric(:unit => '', :description => 'Indicates the number of executing requests', :dstype => 'GAUGE'),
        'RestartCount'  => metric(:unit => '', :description => 'Indicates the number of restarts of the application in the server uptime', :dstype => 'GAUGE'),
        'RequestWaitTime'  => metric(:unit => 'ms', :description => 'Requests held in the queue', :dstype => 'GAUGE'),
        'RequestsQueued'  => metric(:unit => '', :description => 'Throughput of the ASP.NET application on the server', :dstype => 'GAUGE')
      },
      :thresholds => {
      },
    },
    'SystemCounters' =>  { :description => 'System counters',
       :chart => {'min' => 0, 'unit' => ''},
       :heartbeat => false,
       :cmd => 'system_counters.ps1',
       :cmd_line => 'powershell.exe -file /opt/nagios/libexec/system_counters.ps1',
       :metrics =>  {
         'CpuUsage'  => metric(:unit => 'Percent', :description => 'Average percentage of processor time occupied', :dstype => 'GAUGE'),
         'QueueLength'  => metric(:unit => '', :description => 'Processor Queue Length', :dstype => 'GAUGE'),
         'MemoryAvailable'  => metric(:unit => 'MB', :description => 'Amount of physical memory available', :dstype => 'GAUGE'),
         'MemoryPages'  => metric(:unit => 'Percent', :description => 'Amount of read and write requests from memory to disk', :dstype => 'GAUGE')
       },
       :thresholds => {
       },
     },
     'DotNetCounters' =>  { :description => '.Net counters',
        :chart => {'min' => 0, 'unit' => ''},
        :heartbeat => false,
        :cmd => 'dotnet_counters.ps1',
        :cmd_line => 'powershell.exe -file /opt/nagios/libexec/dotnet_counters.ps1',
        :metrics =>  {
          'ExceptionsPerSecond'  => metric(:unit => 'exceptions /sec', :description => 'Number of exceptions per second that the application is throwing', :dstype => 'GAUGE'),
          'TotalCommittedBytes'  => metric(:unit => 'B/sec', :description => 'Shows the amount of virtual memory reserved for the application on the paging file', :dstype => 'GAUGE')
        },
        :thresholds => {
        },
      },
      'WebConnections' =>  { :description => 'Web Connections',
         :chart => {'min' => 0, 'unit' => ''},
         :heartbeat => false,
         :cmd => 'web_connections.ps1',
         :cmd_line => 'powershell.exe -file /opt/nagios/libexec/web_connections.ps1',
         :metrics =>  {
           'CurrentConnections'  => metric(:unit => '', :description => 'Shows the number of active connections with the Web Service', :dstype => 'GAUGE')
         },
         :thresholds => {
         },
       }
  }

resource "dotnetframework",
  :cookbook     => "oneops.1.dotnetframework",
  :design       => true,
  :requires     => {
    :constraint => "1..1",
    :help       => "Installs .net frameworks",
    :services   => 'compute,*mirror'
  },
  :attributes   => {
    "chocolatey_package_source" => 'https://chocolatey.org/api/v2/',
    "dotnet_version_package_name" => '{ ".Net 4.6":"dotnet4.6", ".Net 3.5":"dotnet3.5" }'
  }

chocolatey_package_configure_cmd=  <<-"EOF"

package_name = node.artifact.repository
file_extension = File.extname(node.artifact.location)
uri = URI.parse(node.artifact.location)
file_name = File.basename(uri.path)
file_physical_path = ::File.join(artifact_cache_version_path, file_name)

if file_extension != 'nupkg' && File.exist?(file_physical_path)
 package_location = ::File.join(artifact_cache_version_path, "#\{package_name\}.nupkg")
 ::File.rename(file_physical_path,package_location)
end

chocolatey_package package_name do
  source artifact_cache_version_path
  options "--ignore-package-exit-codes=3010"
  action :install
end

EOF

resource "chocolatey-package",
  :cookbook      => "oneops.1.artifact",
  :design        => true,
  :requires      => {
    :constraint  => "0..*",
    :help        => "Installs chocolatey package"
  },
  :attributes       => {
     :repository    => '',
     :location      => '',
     :install_dir   => '$OO_LOCAL{platform_deployment}',
     :as_user       => 'oneops',
     :as_group      => 'oneops',
     :should_expand => 'false',
     :configure     => chocolatey_package_configure_cmd,
     :migrate       => '',
     :restart       => ''
}

resource "chocopackage",
  :cookbook      => "oneops.1.chocopackage",
  :design        => true,
  :requires      => {
    :constraint  => "0..1",
    :help        => "Installs chocolatey package"
  },
  :attributes       => {
    "chocolatey_package_source" => 'https://chocolatey.org/api/v2/'
  }

resource "nuget-package",
  :cookbook      => "oneops.1.artifact",
  :design        => true,
  :requires      => {
    :constraint  => "0..*",
    :help        => "Installs nuget package"
  },
  :attributes       => {
     :repository    => '',
     :location      => '',
     :install_dir   => '$OO_LOCAL{platform_deployment}',
     :as_user       => 'oneops',
     :as_group      => 'oneops',
     :should_expand => 'true',
     :configure     => '',
     :migrate       => '',
     :restart       => ''
  },
  :payloads => {
    'iis-website' => {
      'description' => 'iis-website',
      'definition' => '{
         "returnObject": false,
         "returnRelation": false,
         "relationName": "base.RealizedAs",
         "direction": "to",
         "targetClassName": "manifest.oneops.1.Artifact",
         "relations": [
           { "returnObject": true,
             "returnRelation": false,
             "relationName": "manifest.DependsOn",
             "direction": "to",
             "targetClassName": "manifest.oneops.1.Iis-website"
           }
         ]
      }'
    }
  }

resource "windowsservice",
  :cookbook     => "oneops.1.windowsservice",
  :design       => true,
  :requires     => {
    :constraint => "0..*",
    :help       => "Installing a service in windows"
  },
  :attributes   => {
    "package_name"             => '',
    "repository_url"           => '',
    "version"                  => 'latest',
    "service_name"             => '',
    "service_display_name"     => '',
    "path"                     => '',
    "physical_path"            => '$OO_LOCAL{app_directory}',
    "user_account"             => 'NT AUTHORITY\LocalService',
    "username"                 => '',
    "password"                 => ''
  }

resource "taskscheduler",
  :cookbook => "oneops.1.taskscheduler",
  :design => true,
  :requires => {
    :constraint => "0..*",
    :help => "Installing a task in taskscheduler"
  },
  :attributes => {
    "package_name"            => '',
    "repository_url"          => '',
    "version"                 => 'latest',
    "task_name"               => '',
    "description"             => '',
    "path"                    => '',
    "arguments"               => '',
    "working_directory"       => '$OO_LOCAL{app_directory}',
    "physical_path"           => '$OO_LOCAL{app_directory}',
    "username"                => '',
    "password"                => '',
    "type"                    => '',
    "execution_time_limit"    => '',
    "start_day"               => '',
    "start_time"              => '',
    "days_interval"           => '',
    "days_of_week"            => '',
    "weeks_interval"          => ''
  }


resource "lb",
  :attributes => {
    "listeners" => "[\"http 80 http 80\"]",
  }

resource "secgroup",
  :attributes => {
    "inbound" => '[ "22 22 tcp 0.0.0.0/0", "3389 3389 tcp 0.0.0.0/0", "80 80 tcp 0.0.0.0/0", "443 443 tcp 0.0.0.0/0"]'
  }

resource "os",
  :attributes => {
    "ostype"  => "windows_2012_r2"
  }

resource "volume",
  :requires       => {
    :constraint   => "1..1"
  },
  :attributes     => {
    "mount_point" => '$OO_LOCAL{drive_name}'
  }

[ { :from => 'iis-website', :to => 'dotnetframework' },
  { :from => 'taskscheduler',  :to => 'volume' },
  { :from => 'iis-website', :to => 'volume' },
  { :from => 'nuget-package', :to => 'iis-website' },
  { :from => 'windowsservice', :to => 'iis-website' },
  { :from => 'dotnetframework', :to => 'os' },
  { :from => 'chocolatey-package', :to => 'volume' },
  { :from => 'chocopackage', :to => 'os' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "iis-website::depends_on::certificate",
  :relation_name => 'DependsOn',
  :from_resource => 'iis-website',
  :to_resource => 'certificate',
  :attributes => {"propagate_to" => "from", "flex" => false, "min" => 1, "max" => 1}

[ 'iis-website', 'taskscheduler', 'dotnetframework', 'nuget-package', 'windowsservice' , 'chocolatey-package' , 'volume', 'os', 'chocopackage' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource   => 'compute',
    :attributes    => { }
end
