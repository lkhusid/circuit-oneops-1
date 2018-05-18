def get_graphite_host
  graphite_endpoint = nil
  graphite_url = node.workorder.rfcCi.ciAttributes.graphite_url
  if graphite_url != ''
    # sanity check if 'graphite_url' does not contain ':', error out
    if not graphite_url.include? ":"
      Chef::Log.error("Graphite URL should be in format of 'address:port'")
      exit 1
    end
    graphite_endpoint = "#{node['kafka']['graphite_url']}"
    #host = graphite_endpoint
    Chef::Log.info("graphite_connection: " + graphite_endpoint)
  else
    Chef::Log.error("No graphite available!")
    exit 1
  end
  return graphite_endpoint
end

# figure out the full hostname
# input could be a `node` object, a hostname or an IP address
IPHOSTMAPCACHE = Hash.new
def get_full_hostname(input) 
  if node['kafka']['use_ptr'] == false
    hostname = input.is_a?(String) ? input : input[:ciAttributes][:hostname]
    # concat short hostname with domain name to get full hostname
    full_hostname =  [hostname, node[:platform_domain_name]].join(".")
    Chef::Log.info("get_full_hostname use_ptr is false and hostname is determined to be " + full_hostname)
    
    return full_hostname
  else
    ip = input.is_a?(String) ? input : input["ciAttributes"]["dns_record"]
    if !IPHOSTMAPCACHE[ip].nil?
      Chef::Log.info("1. get_full_hostname use_ptr is true and hostname full_hostname is determined by cache to be " + IPHOSTMAPCACHE[ip])
      return IPHOSTMAPCACHE[ip]
    end
    
    require 'resolv'
    unless ip =~ Resolv::IPv4::Regex
      # if IP is short hostname, convert it to IP address
      ip = `host #{ip} | awk '{ print $NF }'`.strip
      if !IPHOSTMAPCACHE[ip].nil?
        Chef::Log.info("2. get_full_hostname ip is short hostname, full_hostname is determined by cache to be " + IPHOSTMAPCACHE[ip])
        return IPHOSTMAPCACHE[ip]
      end
    end
    # reverse look up the full hostname from ip address
    full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
    # DNS service may take some time to have the entry of IP -> hostname
    # so using a while loop to repeatly check every 5 seconds
    # TO-DO: implement a timeout to quit the while loop if hostname can not be resolved from IP in rare cases
    tries = 0
    while  tries < 12
      if full_hostname =~ /NXDOMAIN/
        Chef::Log.info("Unable to resolve hostname from IP by PTR, sleep 5s and retry: #{ip}")
        sleep(5)
        full_hostname = `host #{ip} | awk '{ print $NF }' | sed 's/.$//'`.strip
      else
        Chef::Log.info("3. get_full_hostname use_ptr is true and hostname is determined by DNS Resolve ip to be " + full_hostname)
        addToMap(IPHOSTMAPCACHE, full_hostname)
        break;
      end
      tries += 1
    end
    
    if tries == 12
       Chef::Log.info("Timed out - use IP address instead :" + ip)
       full_hostname = ip
       IPHOSTMAPCACHE[ip] = ip
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

def get_server_id_and_internal_zookeeper_electors
  nodes = node.workorder.payLoad.RequiresComputes
  computeNode = Array.new
  nodes.each do |n|
    # use ciName to filter out "console-compute", because they
    # should not be involved in running Zookeeper service
    unless n[:ciName].include? "console"
      computeNode.push(n)
    end
  end
  # `cloud_map` is to store how many and which clouds are used in current deploy
  # each cloud could be identified by the middle number from compute ciName, e.g. 11024920 from `compute-11024920-3`
  # if 3 clouds, `cloud_map` may look like
  # [11024920 -> 1, 4356967 -> 2,  11022468 -> 3]

  # `ip_to_id_map` is to map from ip address to compute id (ciName)

  cloud_map = Hash.new
  ip_to_id_map = Hash.new
  computeNode.each do |n|
    ip_to_id_map.store(n[:ciAttributes][:dns_record], n[:ciName])
    if cloud_map.has_key?(n[:ciName].split("-")[1]) == false
      cloud_map.store(n[:ciName].split("-")[1], cloud_map.length)
    end
  end

  # given the expected zookeeper quorum size
  # calculate the (upper bound) number of electors per cloud
  zk_cluster_size = node['kafka']['zk_quorum_size'].to_i
  if zk_cluster_size.modulo(cloud_map.length).zero?
    num_zk_per_cloud = zk_cluster_size / cloud_map.length
  else
    num_zk_per_cloud = zk_cluster_size / cloud_map.length + 1
  end

  # `zkid` is unique for each Zookeeper instance that will be used in ZK config
  # the way to calculate `zkid` is to split the compute id (ciName) and leverage
  # the values in `cloud_map` as base to produce an unique number
  id = ip_to_id_map[node[:ipaddress]]
  array = id.split("-")
  zkid = cloud_map[array[1]].to_i * 100 + array[2].to_i

  zookeeper_electors = Hash.new
  zookeeper_observers = Hash.new

  # iterate all compute and decide which node should be either electors or observers
  computeNode.each do |n|
    array_split = ip_to_id_map[n[:ciAttributes][:dns_record]].split("-")
    server_id = cloud_map[array_split[1]].to_i * 100 + array_split[2].to_i
    # use hostname, instead of IP address, in config file
    full_hostname = get_full_hostname(n)
    # if the tailing digit of of compute ciName is no larger than the upper bound of electors per cloud
    # and also the current size of `zookeeper_electors` is less than the expected Zookeeper quorum/elector size
    # make this node as Zookeeper elector, otherwise Zookeeper observer
    if n[:ciName].split("-").last.to_i <= num_zk_per_cloud && zookeeper_electors.length < zk_cluster_size
      zookeeper_electors.store(full_hostname, server_id)
    else
      zookeeper_observers.store(full_hostname, server_id)
    end
  end

  kafka_version=node.workorder.rfcCi.ciAttributes.version
  Chef::Log.info("broker version #{kafka_version}")

  # figure out zk connect string
  zk_connect_url = Array.new
  zk_connect_url=`/bin/grep zookeeper.connect= /etc/kafka/server.properties | awk -F\= '{print $2}'`.strip

  if zk_connect_url.empty?
    zk_peers = Array.new
    if node.workorder.rfcCi.ciAttributes.use_external_zookeeper.eql?("false")
      zk_peers = zookeeper_electors.keys
    else
      zk_peers = node.workorder.rfcCi.ciAttributes.external_zk_url.split(",")
    end

    zk_connect_url= (zk_peers.to_a).join(":9091,")
    zk_connect_url = "#{zk_connect_url}:9091"
  end
  Chef::Log.info("zk connect url: #{zk_connect_url}")

  myhostname = `hostname -f`.strip

  require 'rubygems'
  require 'zookeeper'
  begin
    zkClient = Zookeeper.new(zk_connect_url)
    # throws exception so that the inductor retries deployment; total retries 3 times by default
    if !zkClient.connected?
      if !File.exist?('/etc/kafka/broker.properties')
        return (1000 + rand(2147482647)), zkid, zookeeper_electors, zookeeper_observers
      end
      raise "kafka libraries misc.rb: unable to connect to zookeeper #{zk_connect_url}"
    end

    ret = zkClient.get(:path => '/host_brokerid_mappings')
    if ret[:rc] == -101
      zkClient.create(:path => '/host_brokerid_mappings')
    end

    ret = zkClient.get(:path => "/host_brokerid_mappings/#{myhostname}")
    brokerid = ret[:data]
    if brokerid.nil? && ret[:rc] == -101
      if kafka_version.start_with? '0.8.'
        brokerid = `/bin/grep broker.id /etc/kafka/broker.properties | awk -F\= '{print $2}'`.strip
      else
        brokerid = `/bin/grep broker.id "#{node['kafka']['data_dir']}/meta.properties" | awk -F\= '{print $2}'`.strip
      end

      if brokerid.empty?
        brokerid = (1000 + rand(2147482647))
      end
      ret = zkClient.create(:path => "/host_brokerid_mappings/#{myhostname}", :data => "#{brokerid}")

      if ret[:rc] != 0 || ret[:data] != "#{brokerid}"
        # we hope next deployment will persist the mapping, so we do not quit here.
        Chef::Log.error("problem saving brokerid to zookeeper for #{myhostname} brokerid #{brokerid}")
      end
    end
  ensure
    if !zkClient.nil?
      zkClient.close() unless zkClient.closed?
    end
  end
  return brokerid.to_i, zkid, zookeeper_electors, zookeeper_observers
end

# sets up ssl and returns ssl properties
def setup_ssl_get_props
  ssl_props = {}
  attrs = node.workorder.rfcCi.ciAttributes
  if attrs.version.eql?('0.8.2.1')
    ssl_props['advertised.host.name'] = get_full_hostname(node[:hostname])
  else
    #ssl feature is available only for kafka version 9+
    # checking whether ssl is enabled. check secgroup_inbound_rules to decide if plaintext and/or ssl is enabled. 9092 port is for plaintext and 9093 is for ssl
    sslEnabled = attrs.enable_ssl.eql?('true')
    plainTextEnabled = attrs.disable_plaintext.eql?('false')
    saslPlainEnabled = attrs.enable_sasl_plain.eql?('true')
    hostname = `hostname -f`
    hostname.gsub!("\n", "")

    if sslEnabled
      keystore = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] == "bom.oneops.1.Keystore" }
      if keystore.nil? || keystore.size==0
        Chef::Log.error("Keystore component is missing.")
        exit 1
      end
      Chef::Log.info('keystore' + keystore.to_s)
      cert = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] == "bom.oneops.1.Certificate" }
      if cert.nil? || cert.size==0
        Chef::Log.error("Certificate component is missing.")
        exit 1
      end
      Chef::Log.info('cert' + cert.to_s)
      passphrase = cert.first[:ciAttributes].passphrase
      keystore_file = keystore.first[:ciAttributes].keystore_filename
      keystore_password = keystore.first[:ciAttributes].keystore_password
      ca_cert_file = '/tmp/kafka-ca-cert'
      truststore_file = File.dirname(keystore_file)+'/kafka.server.truststore.jks'
      truststore_password = attrs.truststore_password
      if truststore_password.to_s.empty?
        truststorepasswdmissing = "Truststore password is missing."
        Chef::Log.error("#{truststorepasswdmissing}")
        puts "***FAULT:FATAL=#{truststorepasswdmissing}"
        Chef::Application.fatal!(truststorepasswdmissing)
      end
      File.open(ca_cert_file, 'w') { |file| file.write(cert.first[:ciAttributes].cacertkey) }
      # import CA certificate to the truststore
      `keytool -keystore #{truststore_file} -alias CARoot -import -file #{ca_cert_file} -storepass #{truststore_password} -noprompt`
      #setup SSL properties for kafka
      ssl_props['ssl.keystore.location'] = keystore_file
      ssl_props['ssl.key.password'] = passphrase
      ssl_props['ssl.keystore.password'] = keystore_password
      ssl_props['ssl.truststore.password'] = truststore_password
      ssl_props['ssl.truststore.location'] = truststore_file

      if attrs.enable_client_auth.eql?('true') && (attrs.client_certs.nil? || attrs.client_certs.size == 0)
        clientcertsmissing = "Client cert locations are missing when client authentication is enabled."
        Chef::Log.error("#{clientcertsmissing}")
        puts "***FAULT:FATAL=#{clientcertsmissing}"
        Chef::Application.fatal!(clientcertsmissing)
      end     
      
      if attrs.has_key?("client_certs") && !attrs.client_certs.nil? && attrs.client_certs.size > 0
        ssl_props['client.security.protocol'] = "SSL"
        JSON.parse(attrs.client_certs).each do |key|  
         tname = key.split("/").last
         `keytool -keystore #{truststore_file} -alias #{tname} -import -file #{key} -storepass #{truststore_password} -noprompt`
        end
        ssl_props['client.ssl.truststore.location']= truststore_file
        ssl_props['client.ssl.truststore.password'] = truststore_password
      end

      ssl_props['advertised.listeners'] = ssl_props['listeners'] = plainTextEnabled ? "PLAINTEXT://"+ hostname +":9092,SSL://"+ hostname +":9093" : "SSL://"+ hostname +":9093"
     
      ssl_props['ssl.client.auth'] = 'required' if attrs.enable_client_auth.eql?('true')
   
      ssl_props['security.inter.broker.protocol'] = 'SSL' if attrs.disable_plaintext.eql?('true')
      ssl_props['authorizer.class.name'] = 'kafka.security.auth.SimpleAclAuthorizer' if attrs.enable_acl.eql?('true') and attrs.enable_client_auth.eql?('true')

      ssl_props['super.users'] =  attrs.acl_super_user if attrs.enable_acl.eql?('true') and attrs.enable_client_auth.eql?('true')
      Chef::Log.info('Enabled SSL')
    elsif saslPlainEnabled
      ssl_props['advertised.listeners'] = ssl_props['listeners'] = "SASL_PLAINTEXT://"+ hostname +":9092"
    elsif plainTextEnabled
      ssl_props['advertised.listeners'] = ssl_props['listeners'] =  "PLAINTEXT://:9092"
    else
      Chef::Log.error("For plaintext messaging include Port 9092 in secgroup. For SSL include port 9093 in secgroup.")
      exit 1
    end
  end
  return ssl_props
end
