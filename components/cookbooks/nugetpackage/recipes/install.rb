nugetpackage = node['nugetpackage']

nuget_package_details = JSON.parse(node.nugetpackage.nuget_package_details)

nuget_package_details.each do |package_name, package_version|
  Chef::Log.info("installing #{package_name}")
  nugetpackage package_name do
    action :install
    repository_url nugetpackage.repository_url
    physical_path nugetpackage.physical_path
    version package_version
    deployment_directory nugetpackage.install_dir
  end
end
