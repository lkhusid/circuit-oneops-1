def whyrun_supported?
   true
end

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
end

action :install do

  nuget = "C:\\ProgramData\\chocolatey\\lib\\NuGet.CommandLine\\tools\\NuGet.exe"
  version = new_resource.version
  repository_url = new_resource.repository_url
  package_name = new_resource.name
  deployment_directory = new_resource.deployment_directory
  physical_path = new_resource.physical_path

  if version == 'latest'
    cmd = Mixlib::ShellOut.new("#{nuget} list #{package_name} -source #{repository_url} -p")
    cmd.run_command
    version = cmd.stdout.split('\n')
    Chef::Log.fatal "The given package #{package_name} does not exist" unless version.size == 1
    version = version[0].split(' ')[1]
  end

  package_path = ::File.join(deployment_directory,"#{package_name}.#{version}")
  package_physical_path = ::File.join(physical_path, package_name)


  directory package_physical_path do
     action :delete
     recursive true
  end

  directory deployment_directory do
    action :create
    recursive true
  end

  version_option = "-version #{version}"

  powershell_script "Install #{package_name}" do
    code "#{nuget} install #{package_name} -source #{repository_url} #{version_option} -outputdirectory #{deployment_directory} -NoCache"
  end

  directory "#{physical_path}/#{package_name}/#{version}" do
    action :create
    recursive true
  end

  powershell_script "copy nuget package" do
    code "Copy-Item #{package_path}/* -Destination #{physical_path}/#{package_name}/#{version} -Recurse -Force -Exclude *.nupkg"
    only_if { (Dir.entries("#{physical_path}/#{package_name}/#{version}") - %w{ . .. }).empty? }
  end

  directory package_path do
     action :delete
     recursive true
  end

  new_resource.updated_by_last_action(true)
end
