class Library
  def get_dns_service
    cloud_name = $node['workorder']['cloud']['ciName']
    service_attrs = $node['workorder']['services']['dns'][cloud_name]['ciAttributes']

    zone_services = []
    $node['workorder']['services']['dns'].each do |s|

      if s.first =~ /#{cloud_name}\// && s.last['ciAttributes'].has_key?('criteria_type')

        if s.last['ciAttributes']['criteria_type'] == 'platform' && get_ostype == s.last['ciAttributes']['criteria_value']
          zone_services.push(s.last)
        end
      end
    end

    if zone_services.uniq.size == 1
      service_attrs = zone_services.first['ciAttributes']
    end

    return service_attrs
  end

  def get_customer_domain
    if is_windows
      arr = [$node['workorder']['payLoad']['Environment'][0]['ciName'], $node['workorder']['payLoad']['Assembly'][0]['ciName'], get_dns_service['cloud_dns_id'], get_windows_domain]
      customer_domain = '.' + arr.join('.').downcase
    else
      customer_domain = $node['customer_domain'].downcase
    end

    if customer_domain !~ /^\./
      customer_domain = '.' + customer_domain
    end

    return customer_domain
  end

  def is_windows
    return ( get_ostype == 'windows' && get_windows_domain_service )
  end

  def get_ostype

    ostype = 'linux'
    os = $node['workorder']['payLoad']['DependsOn'].select {|d| (d['ciClassName'].split('.').last == 'Os')}
    if $node['workorder']['payLoad'].has_key?('os_payload') && $node['workorder']['payLoad']['os_payload'].first['ciAttributes']['ostype'] =~ /windows/
      ostype = 'windows'
    elsif !os.empty? && os.first['ciAttributes']['ostype'] =~ /windows/
      ostype = 'windows'
    end

    return ostype
  end

  def get_windows_domain
    if get_dns_service['zone'].split('.').last(2) == get_windows_domain_service['ciAttributes']['domain'].split('.').last(2)
      return get_windows_domain_service['ciAttributes']['domain'].downcase
    else
      return get_dns_service['zone'].downcase
    end
  end

  def get_windows_domain_service
    cloud_name = $node['workorder']['cloud']['ciName']
    windows_domain = nil
    if $node['workorder']['payLoad'].has_key?('windowsdomain')
      windows_domain = $node['workorder']['payLoad']['windowsdomain'].first
    elsif $node['workorder']['services'].has_key?('windows-domain')
      windows_domain = $node['workorder']['services']['windows-domain'][cloud_name]
    end

    return windows_domain
  end


  def get_dns_values(components)
    values = Array.new
    components.each do |component|

      attrs = component['ciAttributes']

      dns_record = attrs['dns_record'] || ''

      if dns_record.empty?
        case component['ciClassName']
          when /Compute/
            if attrs.has_key?("public_dns") && !attrs['public_dns'].empty?
              dns_record = attrs['public_dns']+'.'
            else
              dns_record = attrs['public_ip']
            end

            if location == ".int" || dns_entry == nil || dns_entry.empty?
              dns_record = attrs['private_ip']
            end

          when /Lb/
            dns_record = attrs['dns_record']
          when /Cluster/
            dns_record = attrs['shared_ip']
        end
      else
        # dns_record must be all lowercase
        dns_record.downcase!
        # unless ends w/ . or is an ip address
        dns_record += '.' unless dns_record =~ /,|\.$|^\d+\.\d+\.\d+\.\d+$/ || dns_record =~ Resolv::IPv6::Regex
      end



      if dns_record =~ /,/
        values.concat dns_record.split(",")
      else
        values.push(dns_record)
      end
    end
    return values
  end

  def gen_conn(cloud_service,host)
    encoded = Base64.encode64("#{cloud_service['username']}:#{cloud_service['password']}").gsub("\n","")
    conn = Excon.new(
        'https://'+host,
        :headers => {
            'Authorization' => "Basic #{encoded}",
            'Content-Type' => 'application/x-www-form-urlencoded'
        },
        :ssl_verify_peer => false)
    return conn
  end

  def get_gslb_service_name
    env_name = $node['workorder']['payLoad']['Environment'][0]['ciName']
    platform_name = $node['workorder']['box']['ciName']
    cloud_name = $node['workorder']['cloud']['ciName']
    ci = $node['workorder']['payLoad']['DependsOn'][0]
    asmb_name = $node['workorder']['payLoad']['Assembly'][0]['ciName']
    gdns_cloud_service = $node['workorder']['services']["gdns"][cloud_name]
    dc_name = gdns_cloud_service['ciAttributes']['gslb_site_dns_id']

    return [env_name, platform_name, asmb_name, dc_name, ci["ciId"].to_s, "gslbsrvc"].join("-")
  end

  def get_gslb_service_name_by_platform
    env_name = $node['workorder']['payLoad']['Environment'][0]['ciName']
    platform_name = $node['workorder']['box']['ciName']
    cloud_name = $node['workorder']['cloud']['ciName']
    ci = $node['workorder']['box']
    asmb_name = $node['workorder']['payLoad']['Assembly'][0]['ciName']
    gdns_cloud_service = $node['workorder']['services']['gdns'][cloud_name]
    dc_name = gdns_cloud_service['ciAttributes']['gslb_site_dns_id']

    return [env_name, platform_name, asmb_name, dc_name, ci["ciId"].to_s, "gslbsrvc"].join("-")
  end

  def is_wildcard_enabled
    if $node['workorder'].has_key?('config') && !$node['workorder']['config'].empty?
      config = $node['workorder']['config']
      if config.has_key?('is_wildcard_enabled') && !config['is_wildcard_enabled'].empty? && config['is_wildcard_enabled'] == 'true'
        return true
      else
        return false
      end
    end
    return false
  end

  def get_record_type (dns_name, dns_values)
    record_type = "cname"
    ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
    dns_values.each do |dns_value|
      if dns_value =~ Resolv::IPv6::Regex
        record_type = "aaaa"
      end
    end

    if ips.size > 0
      record_type = "a"
    end
    if dns_name =~ /^\d+\.\d+\.\d+\.\d+$/ || dns_name =~ Resolv::IPv6::Regex
      record_type = "ptr"
    end
    if dns_name =~ /^txt-/
      record_type = "txt"
    end
    return record_type
  end

  def check_record (dns_name, dns_value)
    dns_val = dns_value.is_a?(String) ? [dns_value] : dns_value
    dns_type = get_record_type(dns_name,dns_val)
    api_version = "v1.0"

    record = { :name => dns_name.downcase }
    case dns_type
      when "cname"
        record["canonical"] = dns_value
      when "a"
        record["ipv4addr"] = dns_value
      when "aaaa"
        record["ipv6addr"] = dns_value
      when "ptr"
        if dns_name =~ Resolv::IPv4::Regex
          record = {"ipv4addr" => dns_name,
                    "ptrdname" => dns_value}
        elsif dns_name =~ Resolv::IPv6::Regex
          record = {"ipv6addr" => dns_name,
                    "ptrdname" => dns_value}
          api_version = "v1.2" #ipv6addr attribute is recognized only in infoblox api version >= 1.1
        end
      when "txt"
        record = {"name" => dns_name,
                  "text" => dns_value}
    end

    conn = get_infoblox_connection

    res =  conn.request(:method=>:get,:path=>"/wapi/v1.0/network")
    if(res.status != 200)
      raise res.body
    else
      puts "connection successful"
    end

    records = JSON.parse(conn.request(:method=>:get,
                                      :path=>"/wapi/#{api_version}/record:#{dns_type}", :body => JSON.dump(record) ).body)

    puts "Record : #{records}"
    if records.size == 0
      puts "entry is already deleted"
      return true
    else
      puts "entry is available"
      return false
    end
  end

  def get_infoblox_connection
    service = get_dns_service

    host = service['host']
    username = service['username']
    password = service['password']
    domain_name = service['zone']

    encoded = Base64.encode64("#{username}:#{password}").gsub("\n","")
    conn = Excon.new('https://'+host,
                     :headers => {'Authorization' => "Basic #{encoded}"}, :ssl_verify_peer => false)

    return conn
  end

  def get_gslb_domain
    env_name = $node['workorder']['payLoad']['Environment'][0]['ciName']
    assembly_name = $node['workorder']['payLoad']['Assembly'][0]['ciName']
    platform_name = $node['workorder']['box']['ciName']

    cloud_name = $node['workorder']['cloud']['ciName']
    gdns = $node['workorder']['services']['gdns'][cloud_name]['ciAttributes']
    base_domain = gdns['gslb_base_domain']

    if base_domain.nil? || base_domain.empty?
      msg = "#{cloud_name} gdns cloud service has empty gslb_base_domain"
      puts "***FAULT:FATAL=#{msg}"
    end

    $node.set["gslb_base_domain"] = base_domain

# user selected composite of assmb, env, org
    subdomain = $node['workorder']['payLoad']['Environment'][0]['ciAttributes']['subdomain']

    gslb_domain = [platform_name, subdomain, base_domain].join(".")
    if subdomain.empty?
      gslb_domain = [platform_name, base_domain].join(".")
    end
    $node.set["gslb_domain"] = gslb_domain.downcase
  end

  def get_dc_lbserver
    cloud_name = $node['workorder']['cloud']['ciName']
    cloud_service = nil
    dns_service = nil
    if !$node['workorder']['services']['gdns'].nil? &&
        !$node['workorder']['services']['gdns'][cloud_name].nil?

      cloud_service = $node['workorder']['services']['gdns'][cloud_name]
      dns_service = $node['workorder']['services']['dns'][cloud_name]
    end

    if cloud_service.nil? || dns_service.nil?
      put "missing cloud service. services"
    end

    if !cloud_service['ciAttributes'].has_key?('gslb_site_dns_id')
      msg = "gdns service for #{cloud_name} needs gslb_site_dns_id attr populated"
      puts "***FAULT:FATAL=#{msg}"
    end
    platform = $node['workorder']['box']
    platform_name = platform['ciName']

    env_name = $node['workorder']['payLoad']['Environment'][0]['ciName']
    asmb_name = $node['workorder']['payLoad']['Assembly'][0]['ciName']
    org_name = $node['workorder']['payLoad']['Organization'][0]['ciName']
    dc_dns_zone = cloud_service['ciAttributes']['gslb_site_dns_id']+"."+dns_service['ciAttributes']['zone']
    dc_dns_name = [platform_name, env_name, asmb_name, org_name, dc_dns_zone].join(".")

    lbs = $node['workorder']['payLoad']['DependsOn'].select { |d| d['ciClassName'] =~ /Lb/}
    if lbs.nil? || lbs.size==0
      puts "no bom.Lb in DependsOn payload"
      return
    end
    lb = lbs.first
    listener = JSON.parse(lb['ciAttributes']['listeners']).first
    listener_parts = listener.split(" ")
    service_type = listener_parts[0].upcase
    if service_type == "HTTPS"
      service_type = "SSL"
    end

    vport = listener_parts[1]

# dc lb - example: web.prod-1312.core.oneops.dfw.prod.walmart.com-SSL_BRIDGE_443tcp-lb
    dc_lb_name = [platform_name, env_name, asmb_name, org_name, dc_dns_zone].join(".") +
        '-'+service_type+"_"+vport+"tcp-" + platform[:ciId].to_s + "-lb"

    dc_vip = JSON.parse(lb['ciAttributes']['vnames'])[dc_lb_name]
    if dc_vip.nil?
      puts "cannot get dc vip for: #{cloud_name}"
    end

    $node.set['dc_lbvserver_name'] = dc_lb_name
    $node.set['dc_vip'] = dc_vip
    $node.set['dc_entry'] = {'name' => dc_dns_name, 'values' => [dc_vip]}
  end

  def get_provider
    cloud_name = $node['workorder']['cloud']['ciName']
    provider_service = $node['workorder']['services']['dns'][cloud_name]['ciClassName'].split(".").last.downcase
    provider = "fog"
    if provider_service =~ /infoblox|azuredns|designate|ddns/
      provider = provider_service
    end
    return provider
  end

  def build_entry_list

    cloud_name = $node['workorder']['cloud']['ciName']
    service_attrs = get_dns_service

    customer_domain = get_customer_domain

    entries = Array.new

    is_hostname_entry = false

    env = $node['workorder']['payLoad']['Environment'][0]['ciAttributes']
    # netscaler gslb
    depends_on_lb = false
    $node['workorder']['payLoad']['DependsOn'].each do |dep|
      depends_on_lb = true if dep['ciClassName'] =~ /Lb/
    end

    # check for gdns service
    gdns_service = nil
    if $node['workorder']['services'].has_key?('gdns') &&
        $node['workorder']['services']['gdns'].has_key?(cloud_name)

      gdns_service = $node['workorder']['services']['gdns'][cloud_name]
    end

    provider = get_provider

    if env.has_key?("global_dns") && env["global_dns"] == "true" && depends_on_lb &&
        !gdns_service.nil? && gdns_service["ciAttributes"]["gslb_authoritative_servers"] != '[]'
      if provider !~ /azuredns/
        get_gslb_domain
        get_dc_lbserver
      end
    end

    if !$node['workorder']['payLoad'].has_key?('DependsOn')
      puts "missing DependsOn payload"
    end

    lbs = $node['workorder']['payLoad']['DependsOn'].select { |d| d['ciClassName'] =~ /Lb/ }
    os = $node['workorder']['payLoad']['DependsOn'].select { |d| d['ciClassName'] =~ /Os/ }
    cluster = $node['workorder']['payLoad']['DependsOn'].select { |d| d['ciClassName'] =~ /Cluster/ }

    ad_ci = nil
    if is_windows && os.size == 1
      ad_ci = os
      ad_object_name = 'hostname'
    elsif is_windows && cluster.size == 1
      ad_ci = cluster
      ad_object_name = 'cluster_name'
    end

    if ad_ci
      dns_name = (ad_ci[0]['ciAttributes'][ad_object_name] + '.' + get_windows_domain).downcase
      is_hostname_entry = true if os.size == 1

    elsif $node['workorder']['payLoad'].has_key?('Entrypoint')
      ci = $node['workorder']['payLoad']['Entrypoint'][0]
      dns_name = (ci['ciName'] +customer_domain).downcase

    elsif lbs.size > 0
      ci = lbs.first
      ci_name_parts = ci['ciName'].split('-')
      # remove instance and cloud id from ci name
      ci_name_parts.pop
      ci_name_parts.pop
      ci_name = ci_name_parts.join('-')
      dns_name = (ci_name + customer_domain).downcase

    else

      if os.size == 0

        ci_name = $node['workorder']['payLoad']['RealizedAs'].first['ciName']
        dns_name = (ci_name + "." + $node['workorder']['box']['ciName'] + customer_domain).downcase

      else

        if os.size > 1
          puts "unsupported usecase - need to check why there are multiple os for same fqdn"
        end
        is_hostname_entry = true
        ci = os.first

        provider_service = $node['workorder']['services']['dns'][cloud_name]['ciClassName'].split(".").last.downcase
        if provider_service =~ /azuredns/
          dns_name = (ci['ciAttributes']['hostname']).downcase
        else
          dns_name = (ci['ciAttributes']['hostname'] + customer_domain).downcase
        end
      end
    end

    aliases = Array.new
    if $node['workorder']['rfcCi']['ciAttributes'].has_key?('aliases') && !is_hostname_entry
      begin
        aliases = JSON.parse($node['workorder']['rfcCi']['ciAttributes']['aliases'])
      rescue Exception =>e
        puts "could not parse aliases json"
      end
    end

    full_aliases = Array.new
    if $node['workorder']['rfcCi']['ciAttributes'].has_key?('full_aliases') && !is_hostname_entry
      if $node['workorder']['rfcCi']['ciAttributes']['full_aliases'] =~ /\*/ && !is_wildcard_enabled
        puts "unsupported use of wildcard functinality for this organization"
      end
      begin
        full_aliases = JSON.parse($node['workorder']['rfcCi']['ciAttributes']['full_aliases'])
      rescue Exception =>e
        puts "could not parse full_aliases json"
      end
    end

    if service_attrs['cloud_dns_id'].nil? || service_attrs['cloud_dns_id'].empty?
      puts "no cloud_dns_id for dns cloud service"
    end

    # values using DependsOn's dns_record attr
    deps = $node['workorder']['payLoad']['DependsOn'].select { |d| d['ciAttributes'].has_key? 'dns_record' }
    values = get_dns_values(deps)

    # check if dependent component creation is a success or else fail the reciepe execution
    if values.nil? || values.empty?
      puts "Empty dns_record. Please check whether the compute/lb deployment step passed successfully"
    end

    # cloud-level add entry - will loop thru and cleanup & create them later
    entries.push({'name' => dns_name, 'values' => values })
    deletable_entries = [{'name' => dns_name, 'values' => values }]


    # cloud-level short aliases
    aliases.each do |a|
      next if a.empty?
      # skip if user has a short alias same as platform name
      next if a == $node['workorder']['box']['ciName']
      alias_name = a + customer_domain
      entries.push({'name' => alias_name, 'values' => dns_name })
      deletable_entries.push({'name' => alias_name, 'values' => dns_name })
    end


    # platform-level remove cloud_dns_id for primary entry
    if ad_ci
      primary_platform_dns_name = dns_name.split('.').first + get_customer_domain.split('.').select{|i| (i != service_attrs['cloud_dns_id'])}.join('.')
    else
      primary_platform_dns_name = dns_name.split('.').select{|i| (i != service_attrs['cloud_dns_id'])}.join('.')
    end

    if $node['workorder']['rfcCi']['ciAttributes'].has_key?('ptr_enabled') &&
        $node['workorder']['rfcCi']['ciAttributes']['ptr_enabled'] == "true"

      ptr_value = dns_name
      if $node['workorder']['rfcCi']['ciAttributes']['ptr_source'] == "platform"
        ptr_value = primary_platform_dns_name
        if is_hostname_entry
          ptr_value = $node['workorder']['box']['ciName']
          ptr_value += customer_domain.gsub("\."+service_attrs['cloud_dns_id']+"\."+service_attrs['zone'],"."+service_attrs['zone'])
        end
      end

      values.each do |ip|
        next unless ip =~ /^\d+\.\d+\.\d+\.\d+$/ || ip =~ Resolv::IPv6::Regex
        ptr = {'name' => ip, 'values' => ptr_value.downcase}
        entries.push(ptr)
        deletable_entries.push(ptr)
      end
    end


    # platform level
    if $node['workorder']['cloud']['ciAttributes']['priority'] != "1"

      # clear platform if not primary and not gslb
      if !$node.has_key?('gslb_domain')
        entries.push({'name' => primary_platform_dns_name, 'values' => [] })
      end

    else

      if $node.has_key?('gslb_domain') && !$node['gslb_domain'].nil?
        value_array = [ $node['gslb_domain'] ]
      else
        # infoblox doesnt support round-robin cnames so need to get other primary cloud-level ip's
        value_array = []
        if values.class.to_s == "String"
          value_array.push(values)
        else
          value_array += values
        end

      end

      is_a_record = false
      value_array.each do |val|
        if val =~ /^\d+\.\d+\.\d+\.\d+$/ || val =~ Resolv::IPv6::Regex
          is_a_record = true
        end
      end

      if $node['dns_action'] != "delete" ||
          ($node['dns_action'] == "delete" && $node['is_last_active_cloud']) ||
          ($node['dns_action'] == "delete" && is_a_record)

        entries.push({'name' => primary_platform_dns_name, 'values' => value_array })
        deletable_entries.push({'name' => primary_platform_dns_name, 'values' => value_array })
      end


      aliases.each do |a|
        next if a.empty?
        next if $node['dns_action'] == 'delete' && !$node['is_last_active_cloud']
        # skip if user has a short alias same as platform name
        next if a == $node['workorder']['box']['ciName']

        alias_name = a  + customer_domain
        alias_platform_dns_name = alias_name.gsub("\."+service_attrs['cloud_dns_id']+"\."+service_attrs['zone'],"."+service_attrs['zone']).downcase

        if $node.has_key?('gslb_domain') && !$node['gslb_domain'].nil?
          primary_platform_dns_name = $node['gslb_domain']
        end

        entries.push({'name' => alias_platform_dns_name, 'values' => primary_platform_dns_name })
        deletable_entries.push({'name' => alias_platform_dns_name, 'values' => primary_platform_dns_name })
      end

      if !full_aliases.nil?
        full_aliases.each do |full|
          next if $node['dns_action'] == "delete" && !$node['is_last_active_cloud']

          full_value = primary_platform_dns_name
          if $node.has_key?('gslb_domain') && !$node['gslb_domain'].nil?
            full_value = $node['gslb_domain']
          end

          entries.push({'name' => full, 'values' => full_value, 'is_hijackable' => $node['workorder']['rfcCi']['ciAttributes']['hijackable_full_aliases'] })
          deletable_entries.push({'name' => full, 'values' => full_value})
        end
      end

    end

    if $node.has_key?('dc_entry')
      if $node['dns_action'] != "delete" ||
          ($node['dns_action'] == "delete" && $node['is_last_active_cloud_in_dc'])

        entries.push($node['dc_entry'])
        deletable_entries.push($node['dc_entry'])
      end
    end

    entries_hash = {}
    entries.each do |entry|
      key = entry['name']
      entries_hash[key] = entry['values']
    end
    puts "***RESULT:entries=#{JSON.dump(entries_hash)}"
    return entries
  end

end