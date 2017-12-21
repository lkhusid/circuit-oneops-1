require 'json'

hostname = nil
node.workorder.payLoad[:DependsOn].each do |dep|
  if dep["ciClassName"] =~ /Fqdn/
    hostname = dep
    break
  end
end

Chef::Log.info("------------------------------------------------------")
Chef::Log.info("Hostname: "+hostname.inspect.gsub("\n"," "))
Chef::Log.info("------------------------------------------------------")

# compute needs to depend on the hostname
if hostname.nil?
  Chef::Log.error("no DependsOn hostname (Fqdn) - exit 1")
  exit 1
end

# hostname will be used in config files, instead of IP address
# there are two ways to figure out the hostname of each compute

# (1) if PTR record is enabled, no more things to do and directly
# use reverse lookup (e.g. `host` cmd) to get hostname when needed.
# (2) if PTR record is not enabled, use the dependency b/w Kafka
# and hostname to figure out the domain name.
# when needs hostname, concat node[:hostname] with domain name.

Chef::Log.info("ciBaseAttributes content: "+hostname["ciBaseAttributes"].inspect.gsub("\n"," "))
Chef::Log.info("ciAttributes content: "+hostname["ciAttributes"].inspect.gsub("\n"," "))

if !hostname["ciBaseAttributes"]["entries"].nil? && !hostname["ciBaseAttributes"]["entries"].empty?
  attr = hostname["ciBaseAttributes"]
  Chef::Log.info("use ciBaseAttributes")
else
  attr = hostname["ciAttributes"]
  Chef::Log.info("use ciAttributes")
end

# if ptr_enabled is not enabled
if attr["ptr_enabled"] == "false"
  Chef::Log.info("PTR is not set")
  node.set['kafka']['use_ptr'] = false;
  
  hash = JSON.parse(attr["entries"])
  
  # remove any entry in hash that its key looks similar to IPv4 address (this kind of entry could come from PTR, though PTR enabled case should not go to this step)
  # remove any entry in hash that its value is a String (this kind of entry could come from setting a CNAME for alias)
  # the remaining entries should be purely looking like: [hostname -> IP address]
  require 'resolv'
  hash.delete_if {|key, value| key =~ Resolv::IPv4::Regex}
  hash.delete_if {|key, value| value.is_a?(String)}

  # hostnames are stored in key part of the hash
  arr = hash.keys

  # there could be 2 types of hostnames: (1) platform-level hostname, (2) cloud-level hostname. For example,
 
  # platform-level hostname always comes shorter in string length, so sort based on the string length and retrieve the shortest hostname, which is presumed to be the platform-level hostname
  platform_hostname = arr.sort_by{|s| s.length }[0]
  Chef::Log.info("platform_hostname: " +  platform_hostname)
  
  arr = platform_hostname.split(".")[1..-1]

  # join elements in arr with "." to get the domain name
  node.set[:platform_domain_name] = arr.join(".")

  Chef::Log.info("Platform-level domain name: "+ node[:platform_domain_name])
end
