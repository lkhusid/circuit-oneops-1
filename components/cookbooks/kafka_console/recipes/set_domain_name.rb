require 'json'

fqdn = nil
node.workorder.payLoad[:DependsOn].each do |dep|
  if dep["ciClassName"] =~ /Fqdn/
    fqdn = dep
    break
  end
end

Chef::Log.info("------------------------------------------------------")
Chef::Log.info("Fqdn: "+fqdn.inspect.gsub("\n"," "))
Chef::Log.info("------------------------------------------------------")


if fqdn.nil?
  Chef::Log.error("no DependsOn Fqdn - exit 1")
  exit 1
end

# platform-level FQDN will be used in config files, instead of IP address
# there are two ways to figure out the platform-level FQDN

# (1) if PTR record is enabled, no more things to do and directly
# use reverse lookup (e.g. `host` cmd) to get hostname when needed.
# (2) if PTR record is not enabled, use the dependency b/w kafka_console
# and FQDN to figure out the domain name.
# when needs platform-level FQDN, concat OneOps platform name (node.workorder.box.ciName) with domain name.

Chef::Log.info("ciBaseAttributes content: "+fqdn["ciBaseAttributes"].inspect.gsub("\n"," "))
Chef::Log.info("ciAttributes content: "+fqdn["ciAttributes"].inspect.gsub("\n"," "))

if !fqdn["ciBaseAttributes"]["entries"].nil? && !fqdn["ciBaseAttributes"]["entries"].empty?
  attr = fqdn["ciBaseAttributes"]
  Chef::Log.info("use ciBaseAttributes")
else
  attr = fqdn["ciAttributes"]
  Chef::Log.info("use ciAttributes")
end

if attr["ptr_enabled"] == "false"
  Chef::Log.info("PTR is not set")
  node.set['kafka_console']['use_ptr'] = false;
    
  # attr[["entries"] could be 'String', but in hash format. Such as,
  # so convert attr["entries"] into hash format by JSON,parse()
  hash = JSON.parse(attr["entries"])
  
  # remove any entry in hash that its key looks similar to IPv4 address (this kind of entry could come from PTR, though PTR enabled case should not go to this step)
  # remove any entry in hash that its value is a String (this kind of entry could come from setting a CNAME for alias)
  # the remaining entries should be purely looking like: [hostname -> IP address]
  require 'resolv'
  hash.delete_if {|key, value| key =~ Resolv::IPv4::Regex}
  hash.delete_if {|key, value| value.is_a?(String)}
    
  # hostnames are stored in key part of the hash
  arr = hash.keys
    
  # there could be 2 types of fqdn: (1) platform-level fqdn, (2) cloud-level fqdn.
 
  # platform-level fqdn always comes shorter in string length, so sort based on the string length and retrieve the shortest fqdn, which is the platform-level fqdn
    
  platform_fqdn = arr.sort_by{|s| s.length }[0]
  Chef::Log.info("platform_fqdn: " +  platform_fqdn)
    
  arr = platform_fqdn.split(".")[1..-1]
    
  # join elements in arr with "." to get the domain name
  node.set[:platform_domain_name] = arr.join(".")

  Chef::Log.info("Platform-level domain name: "+ node[:platform_domain_name])
end

