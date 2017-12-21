application = node.workorder.rfcCi.ciAttributes

version = application.version
package_name = application.package_name
repository_url = application.repository_url
output_directory = ::File.join(File.dirname(application.physical_path), "platform_deployment")
Chef::Log.info "The output directory is #{output_directory}"


nuget = "C:\\ProgramData\\chocolatey\\lib\\NuGet.CommandLine\\tools\\NuGet.exe"
oo_local_vars = node.workorder.payLoad.OO_LOCAL_VARS if node.workorder.payLoad.has_key?(:OO_LOCAL_VARS)

Array(oo_local_vars).each do |var|
  if var[:ciName] == "nuget_exe"
    nuget = "#{var[:ciAttributes][:value]}"
  end
end

if version == 'latest'
  cmd = Mixlib::ShellOut.new("#{nuget} list #{package_name} -source #{repository_url} -p")
  cmd.run_command
  version = cmd.stdout.split('\n')
  Chef::Log.fatal "The given package #{package_name} does not exist" unless version.size == 1
  version = version[0].split(' ')[1]
end

node.set['workorder']['rfcCi']['ciAttributes']['package_version'] = version
Chef::Log.info "The package_version is #{node['workorder']['rfcCi']['ciAttributes']['package_version']}"
package_path = ::File.join(output_directory,"#{package_name}.#{version}")
package_physical_path = ::File.join(application.physical_path, package_name)

directory package_physical_path do
   action :delete
   recursive true
end

directory output_directory do
  action :create
  recursive true
end

version_option = "-version #{version}"

powershell_script "Install #{package_name}" do
  code "#{nuget} install #{package_name} -source #{repository_url} #{version_option} -outputdirectory #{output_directory} -NoCache"
end

directory "#{application.physical_path}/#{package_name}/#{version}" do
  action :create
  recursive true
end

powershell_script "copy nuget package" do
  code "Copy-Item #{package_path}/* -Destination #{application.physical_path}/#{package_name}/#{version} -Recurse -Force -Exclude *.nupkg"
  only_if { (Dir.entries("#{application.physical_path}/#{package_name}/#{version}") - %w{ . .. }).empty? }
end

directory package_path do
   action :delete
   recursive true
end
