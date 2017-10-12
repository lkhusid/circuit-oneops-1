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
   package_source_url = mirror_url_nil_or_empty ? node.chocopackage.chocolatey_package_source : mirror_pkg_source_url

   Chef::Log.info("Using chocolatey repo #{package_source_url}")

   chocolatey_package_details = JSON.parse(node.chocopackage.chocolatey_package_details)
   chocolatey_package_details.each do |package_name, package_version|
     Chef::Log.info("installing #{package_name}")
     chocolatey_package package_name do
       source package_source_url
       options "--ignore-package-exit-codes=3010"
       version package_version
       action :install
     end
   end

  else
    Chef::Log.fatal("Please upgrade your chef client as chocolatey_package resource only available in version >= 12.7")
  end

else
  Chef::Log.fatal("Chocopackage component is not supported on #{node['platform_family']}")
end
