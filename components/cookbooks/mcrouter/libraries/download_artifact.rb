require 'rubygems'
require 'excon'

module PackageFinder

  #
  # Find a proper installer package for the given version, processor architecture and package type
  # from the given download/mirror site. This is required since there is no consistent naming convention
  # followed for the couch base installers. This method would search for different combinations of version,
  # arch and package types to find a first matching package file.
  #
  # @param base_url this can be the official download  or any mirror site url
  # @param name installer base file name
  # @param version package version
  # @param arch package processor architecture (<b>x86_64</b> (64 bit) or <b>x86</b> (32 bit))
  # @param package_type  package type (<b>rpm</b> or <b>deb</b>)
  #
  # @return an array containing the package's absolute download url and fully qualified package file name.
  # Empty if it couldn't find any valid installer packages.


  def self.search_for(base_url, name, version, arch, package_type)

    ["-#{version}-#{arch}.#{package_type}",
     "_#{version}_#{arch}.#{package_type}",
     "_#{arch}_#{version}.#{package_type}",
     "-#{version}.#{package_type}",].each do |suffix|
      file_name ="#{name}#{suffix}"
      url = "#{base_url.chomp('/')}/#{version}/#{file_name}"
      Chef::Log.info("Checking package file: #{url} ")
      Excon.defaults[:ssl_verify_peer] = false
      res = Excon.head(url)
      if res.status == 200
        Chef::Log.info("Found package file: #{file_name}")
        return url, file_name
      end
    end
    Chef::Log.error("Couldn't find package #{name} for version: #{version}, arch: #{arch} & type: #{package_type}")
    []
  end
end
