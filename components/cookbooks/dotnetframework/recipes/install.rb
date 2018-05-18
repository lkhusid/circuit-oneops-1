if node['platform_family'] == 'windows'

  CHEF_VERSION_EXPRESSION = /^Chef:\s(?<major>\d\d)\.(?<minor>\d{1}+)\.(?<patch>\d{1}+)$/
  capture = CHEF_VERSION_EXPRESSION.match(`chef-client -v`.chomp)

  if capture['major'].to_i >= 12 && capture['minor'].to_i >= 7

   mirror_svc = node[:workorder][:services][:mirror]
   if !mirror_svc.nil?
     cloud = node.workorder.cloud.ciName
     mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors])
     mirror_pkg_source_url = mirror['chocorepo']
   end

   mirror_url_nil_or_empty = mirror_pkg_source_url.nil? || mirror_pkg_source_url.empty?
   package_source_url = mirror_url_nil_or_empty ? node.dotnetframework.chocolatey_package_source : mirror_pkg_source_url

   Chef::Log.info("Using chocolatey repo #{package_source_url}")

   if node.dotnetframework.install_dotnetcore.downcase == "true"
     dotnet_core_package_name = node.dotnetframework.dotnet_core_package_name
     dotnet_core_versions = JSON.parse(node.dotnetframework.dotnet_core_version)
     dotnet_core_versions.each do |version|
       Chef::Log.info("installing #{dotnet_core_package_name} #{version}")
       chocolatey_package dotnet_core_package_name do
         source package_source_url
         version version
         options "--ignore-package-exit-codes=3010"
         action :install
       end
     end
     powershell_script "stopping was service and starting w3svc service" do
       code <<-EOH
          net stop was /y
          net start w3svc
       EOH
       only_if { dotnet_core_package_name == "dotnetcore-windowshosting" }
     end
   else
     dotnet_version_package_name = JSON.parse(node.dotnetframework.dotnet_version_package_name)
     dotnet_version_package_name.each do |dotnet_version,package_name|
       Chef::Log.info("installing #{dotnet_version}")
       chocolatey_package package_name do
         source package_source_url
         options "--ignore-package-exit-codes=3010"
         action :install
       end
     end
   end

  else
    Chef::Log.fatal("Please upgrade your chef client as chocolatey_package resource only available in version >= 12.7")
  end

else
  Chef::Log.fatal(".net framework not supported on #{node['platform_family']}")
end
