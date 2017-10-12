include_pack "genericlb"

name "dotnet-framework"
description ".Net Framework"
type "Platform"
category "Worker Application"

environment "single", {}
environment "redundant", {}

platform :attributes => {'autocomply' => 'true'}

variable "drive_name",
  :description => 'drive name',
  :value       => 'E'

variable "platform_deployment",
  :description => 'Downloads the nuget packages',
  :value       => 'e:\platform_deployment'

variable "app_directory",
  :description => 'Application directory',
  :value       => 'e:\apps'

variable "nuget_exe",
  :description => 'Nuget exe path',
  :value       => 'C:\ProgramData\chocolatey\lib\NuGet.CommandLine\tools\NuGet.exe'

chocolatey_package_configure_cmd=  <<-"EOF"

package_name = node.artifact.repository
file_extension = File.extname(node.artifact.location)
uri = URI.parse(node.artifact.location)
file_name = File.basename(uri.path)
file_physical_path = ::File.join(artifact_cache_version_path, file_name)

if file_extension != 'nupkg' and File.exist?(file_physical_path)
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
     :version       => '',
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


resource "dotnetframework",
  :cookbook     => "oneops.1.dotnetframework",
  :design       => true,
  :requires     => {
    :constraint => "1..1",
    :help       => "Installs .net frameworks",
    :services   => 'compute,*mirror'
  },
  :attributes   => {
    "chocolatey_package_source" => 'https://chocolatey.org/api/v2/'
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


resource "secgroup",
  :attributes => {
    "inbound" => '[ "22 22 tcp 0.0.0.0/0", "3389 3389 tcp 0.0.0.0/0" ]'
  }

resource "compute",
  :attributes => {"size" => "M-WIN"}

resource "os",
  :requires => {
    "services" => "compute,dns,mirror,*ntp,*windows-domain"
  },
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

[ { :from => 'windowsservice',  :to => 'volume' },
  { :from => 'taskscheduler',  :to => 'volume' },
  { :from => 'dotnetframework',  :to => 'os' },
  { :from => 'chocolatey-package', :to => 'volume' },
  { :from => 'chocopackage', :to => 'os' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource => link[:to],
    :attributes => { "flex" => false, "min" => 1, "max" => 1 }
end

[ 'windowsservice', 'taskscheduler', 'dotnetframework','chocolatey-package' ,'volume','os', 'chocopackage' ].each do |from|
  relation "#{from}::managed_via::compute",
    :except => [ '_default' ],
    :relation_name => 'ManagedVia',
    :from_resource => from,
    :to_resource => 'compute',
    :attributes => { }
end
