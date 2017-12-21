ZKIPHOSTMAPCACHE = Hash.new
def get_full_hostname(fqdn)
  if node['kafka_console']['use_ptr'] == false
    hostname = fqdn.is_a?(String) ? fqdn : fqdn[:ciAttributes][:hostname]
    full_hostname =  [hostname, node[:platform_domain_name]].join(".")
  else
    ip = fqdn.is_a?(String) ? fqdn : fqdn[:ciAttributes][:dns_record]
    if !ZKIPHOSTMAPCACHE[ip].nil?
      Chef::Log.info("1. get_full_hostname use_ptr is true and hostname full_hostname is determined by cache to be " + ZKIPHOSTMAPCACHE[ip])
      return ZKIPHOSTMAPCACHE[ip]
    end

    require 'resolv'
    unless ip =~ Resolv::IPv4::Regex
      # ip is short hostname, convert it to ip address
      ip = `host #{ip} | awk '{ print $NF }'`.strip
      if !ZKIPHOSTMAPCACHE[ip].nil?
        Chef::Log.info("2. get_full_hostname ip is short hostname, full_hostname is determined by cache to be " + ZKIPHOSTMAPCACHE[ip])
        return ZKIPHOSTMAPCACHE[ip]
      end
    end
    full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
    tries = 0
    while  tries < 12
      if full_hostname =~ /NXDOMAIN/
        Chef::Log.info("Unable to resolve fqdn from IP by PTR, sleep 5s and retry: #{ip}")
        sleep(5)
        full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
      else
        Chef::Log.info("3.ZKIPHOSTMAPCACHE get_full_hostname use_ptr is true and hostname is determined by DNS Resolve ip to be " + full_hostname)
         full_hostname.gsub!(/\s+/, ' ')
         full_hostname.gsub!(/\n/, " ")
         if full_hostname.match(" ")
           values = full_hostname.split(" ")
           full_hostname = values[0]
         end
         addToMap(ZKIPHOSTMAPCACHE, full_hostname)
        break;
      end

      tries += 1
    end

    if tries == 12
      Chef::Log.info("Timed out - use IP address instead :" + ip)
      full_hostname = ip
      ZKIPHOSTMAPCACHE[ip] = ip
    end
  end
  Chef::Log.info("full_hostname is: #{full_hostname}")
  return full_hostname
end

def addToMap(iphostmappings, host)
   temps = host.split(".")
   subdomain_name = temps[1..-1].join(".")
   #temps[0] is the short hostname
   tokens = temps[0].split("-")
   cloud_number = tokens[tokens.length - 3]
   
   #resolve all ip to hostname in the same cloud
   nodes = node.workorder.payLoad.RequiresComputes
   nodes.each do |n|
      if !n[:ciAttributes].nil? && !n[:ciAttributes][:hostname].nil? && (n[:ciAttributes][:hostname].is_a? String) && !cloud_number.nil? && n[:ciAttributes][:hostname].include?(cloud_number)
         iphostmappings[n[:ciAttributes][:dns_record]] = "#{n[:ciAttributes][:hostname]}.#{subdomain_name}"
         Chef::Log.info("addToMap: #{n[:ciAttributes][:dns_record]} ==> #{n[:ciAttributes][:hostname]}, domain: #{subdomain_name}")
      end
   end
end
