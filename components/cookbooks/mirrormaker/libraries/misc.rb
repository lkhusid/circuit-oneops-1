# sets up ssl and returns ssl properties
def setup_ssl_get_props

  ssl_props = {} #Hash object for ssl properties.
  attrs = node.workorder.rfcCi.ciAttributes

  sslEnabled = attrs.enable_ssl_for_consumer.eql?('true') || attrs.enable_ssl_for_producer.eql?('true') ##Either producer or consumer side ssl is needed ?
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
    truststore_password = attrs.mm_truststore_password ## mirrormaker truststore password.

    if truststore_password.nil?  || truststore_password.size==0
	Chef::Application.fatal!("Please enter the truststore password")
      exit 1
    end
    ca_cert_file = '/tmp/kafka-ca-cert'

    truststore_file = File.dirname(keystore_file)+'/mirrormaker.truststore.jks'
    File.open(ca_cert_file, 'w') { |file| file.write(cert.first[:ciAttributes].cacertkey) } # cacertkey attribute will have CA certificate chain of trust(root, intermediate, issuing)

    # import CA certificate chain of trust to the truststore

    `keytool -keystore #{truststore_file} -alias CARoot -import -file #{ca_cert_file} -storepass #{truststore_password} -noprompt`

    #setup SSL properties for kafka rest
    ssl_props['security.protocol'] = "SSL"
    ssl_props['ssl.keystore.location'] = keystore_file
    ssl_props['ssl.key.password'] = passphrase
    ssl_props['ssl.keystore.password'] = keystore_password
    ssl_props['ssl.truststore.location']= truststore_file
    ssl_props['ssl.truststore.password'] = truststore_password

    #client_certs location is for mutual auth using self-signed certificates. Mostly to support dev/qa testing.
     if attrs.has_key?("client_certs") &&  JSON.parse(attrs.client_certs).size > 0

         JSON.parse(attrs.client_certs).each do |key|
  		tname = key.split("/").last
  		`keytool -keystore #{truststore_file} -alias #{tname} -import -file #{key} -storepass #{truststore_password} -noprompt`
       end

    end
  else # if neither producer nor consumer uses ssl then PLAINTEXT
     ssl_props['security.protocol'] = "PLAINTEXT"
  end
  return ssl_props
end
