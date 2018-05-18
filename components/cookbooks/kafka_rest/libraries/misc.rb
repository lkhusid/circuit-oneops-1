# sets up ssl and returns ssl properties
def setup_ssl_get_props
  ssl_props = {}
  attrs = node.workorder.rfcCi.ciAttributes
     
    sslEnabled = attrs.enable_ssl.eql?('true') 
	kafkaclientauth = attrs.client_auth_enable.eql?('true')
  
    if sslEnabled
      keystore = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] == "bom.oneops.1.Keystore" }
      if keystore.nil? || keystore.size==0
        Chef::Application.fatal!("Keystore component is missing.")
      end
      cert = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] == "bom.oneops.1.Certificate" }
      if cert.nil? || cert.size==0
        Chef::Application.fatal!("Certificate component is missing.")
        exit 1
      end

      passphrase = cert.first[:ciAttributes].passphrase
      keystore_file = keystore.first[:ciAttributes].keystore_filename
      keystore_password = keystore.first[:ciAttributes].keystore_password
      truststore_password = attrs.rest_truststore_password
      
      if truststore_password.nil?  || truststore_password.size==0 
		Chef::Application.fatal!("Please enter the truststore password")
        exit 1
      end
      ca_cert_file = '/tmp/kafka-ca-cert'

      truststore_file = File.dirname(keystore_file)+'/kafka.client.truststore.jks'
      File.open(ca_cert_file, 'w') { |file| file.write(cert.first[:ciAttributes].cacertkey) }
      
      # import CA certificate to the truststore
      
      `keytool -keystore #{truststore_file} -alias CARoot -import -file #{ca_cert_file} -storepass #{truststore_password} -noprompt`
      
      #setup SSL properties for kafka rest
    
	  ssl_props['ssl.keystore.location'] = keystore_file
      ssl_props['ssl.key.password'] = passphrase
      ssl_props['ssl.keystore.password'] = keystore_password
      ssl_props['ssl.truststore.location']= truststore_file
      ssl_props['ssl.truststore.password'] = truststore_password
      
      
      if kafkaclientauth
        ssl_props['client.ssl.keystore.location'] = keystore_file
        ssl_props['client.ssl.key.password'] = keystore_password
        ssl_props['client.ssl.keystore.password'] = keystore_password
      end
      
       if attrs.has_key?("client_certs") &&  JSON.parse(attrs.client_certs).size > 0 
           
           ssl_props['client.security.protocol'] = "SSL"
           JSON.parse(attrs.client_certs).each do |key|  
    		tname = key.split("/").last
    		`keytool -keystore #{truststore_file} -alias #{tname} -import -file #{key} -storepass #{truststore_password} -noprompt`
         end
        ssl_props['client.ssl.truststore.location']= truststore_file
        ssl_props['client.ssl.truststore.password'] = truststore_password
      end
    else
       ssl_props['client.security.protocol'] = "PLAINTEXT"
     end
  return ssl_props
end