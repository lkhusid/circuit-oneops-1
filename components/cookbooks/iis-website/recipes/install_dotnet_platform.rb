if node[:workorder][:services].has_key?('dotnet-platform')

  cloud = node.workorder.cloud.ciName
  chocolatey_package_details = JSON.parse(node[:workorder][:services]["dotnet-platform"][cloud]['ciAttributes']['chocolatey_package_details'])
  chocolatey_package_source = node[:workorder][:services]['dotnet-platform'][cloud]['ciAttributes']['chocolatey_package_source']

  mirror_svc = node[:workorder][:services][:mirror]
  if !mirror_svc.nil?
    mirror = JSON.parse(mirror_svc[cloud][:ciAttributes][:mirrors])
    mirror_pkg_source_url = mirror['chocorepo']
  end

  mirror_url_nil_or_empty = mirror_pkg_source_url.nil? || mirror_pkg_source_url.empty?
  package_source_url = mirror_url_nil_or_empty ? chocolatey_package_source : mirror_pkg_source_url

  Chef::Log.info("Using chocolatey repo #{package_source_url}")

  chocolatey_package_details.each do |package_name, package_version|
    Chef::Log.info("installing #{package_name}")
    chocolatey_package package_name do
      source package_source_url
      options "--ignore-package-exit-codes=3010"
      version package_version
      action :install
    end
  end

end
