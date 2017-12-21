base_url = node['mcrouter']['base_url']
package_name = node['mcrouter']['package_name']
version = node['mcrouter']['version']
arch = node['mcrouter']['arch']
pkg_type = node['mcrouter']['pkg_type']
sha256 = node['mcrouter']['sha256']

pkg = PackageFinder.search_for(base_url, package_name, version, arch, pkg_type)

# Get the url and filename from the package.
if pkg.empty?
  Chef::Application.fatal!("Can't find the install package.")
end
url = pkg[0]
file_name = pkg[1]
dl_file = ::File.join(Chef::Config[:file_cache_path], '/', file_name)

# Download the package
remote_file dl_file do
  source url
  checksum sha256 if !sha256.empty?
  action :create_if_missing
end

yum_package 'boost'
yum_package 'gflags'
yum_package 'glog'
yum_package 'jemalloc'
yum_package 'double-conversion'

# Install the package
package "#{package_name}-#{version}" do
  source dl_file
  provider Chef::Provider::Package::Rpm if pkg_type == 'rpm'
  provider Chef::Provider::Package::Dpkg if pkg_type == 'deb'
  action :install
end
