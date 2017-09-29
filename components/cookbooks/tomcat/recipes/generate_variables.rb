# override attribute defaults w/ values from workorder
node.set['tomcat_owner'] = node['tomcat']['user']
node.set['tomcat_group'] = node['tomcat']['group']

if node['tomcat'].has_key?("tomcat_user") && !node['tomcat']['tomcat_user'].empty?
  node.set['tomcat_owner'] = node['tomcat']['tomcat_user']
end

if node['tomcat'].has_key?("tomcat_group") && !node['tomcat']['tomcat_group'].empty?
  node.set['tomcat_group'] = node['tomcat']['tomcat_group']
end

(node['tomcat'].has_key?('protocol') && !node['tomcat']['protocol'].empty?) ?
    node.set['tomcat']['connector']['protocol'] = node['tomcat']['protocol'] :
    node.set['tomcat']['connector']['protocol'] = 'HTTP/1.1'

(node['tomcat'].has_key?('advanced_connector_config') && !node['tomcat']['advanced_connector_config'].empty?) ?
    node.set['tomcat']['connector']['advanced_connector_config'] = node['tomcat']['advanced_connector_config'] :
    node.set['tomcat']['connector']['advanced_connector_config'] = '{"connectionTimeout":"20000"}'

Chef::Log.info(" protocol  #{node['tomcat']['connector']['protocol']} - connector config #{node['tomcat']['connector']['advanced_connector_config']} ssl_configured : #{node['tomcat']['connector']['ssl_configured']}")

# Check to see if user is choosing 8.5.12+ and Blocking connector.  This combo doesn't work so default to NonBlocking Connector
if (node['tomcat']['version'].gsub(/\..*/,"") != "7" && node['tomcat']['protocol'] == "org.apache.coyote.http11.Http11Protocol")
  Chef::Log.warn("Tomcat 8.5.12 or greater is selected with Blocking Java Connector.  This configuration does not exist.  Defaulting to Non-Blocking Java Connector only.")
  node.set['tomcat']['connector']['protocol'] = "org.apache.coyote.http11.Http11NioProtocol"
end

Chef::Log.info(" protocol  #{node['tomcat']['connector']['protocol']} - connector config #{node['tomcat']['connector']['advanced_connector_config']} ssl_configured : #{node['tomcat']['connector']['ssl_configured']}")

tomcat_version_name = "tomcat"+node.workorder.rfcCi.ciAttributes.version[0,1]
node.set['tomcat']['tomcat_version_name'] = tomcat_version_name

#Fixed the defaults for executor thread pool, uses executor.
node.set['tomcat']['executor']['executor_name']=node['tomcat']['executor_name']
node.set['tomcat']['executor']['max_threads']= node['tomcat']['max_threads']
node.set['tomcat']['executor']['min_spare_threads']=node['tomcat']['min_spare_threads']

depends_on=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Javaservicewrapper/ }
depends_on_keystore=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] !~ /Keystore/ }

Chef::Log.info("retrieving keystore location from keyStore but only if we depend on one")

if (!depends_on_keystore.nil? && !depends_on_keystore.empty?)
    Chef::Log.info("do depend on keystore, with filename: #{depends_on_keystore[0]['ciAttributes']['keystore_filename']} ")
    #stash values which will be needed in server.xml template .erb
    node.set['tomcat']['keystore_path'] = depends_on_keystore[0]['ciAttributes']['keystore_filename']

    node.set['tomcat']['keystore_pass'] = depends_on_keystore[0]['ciAttributes']['keystore_password']
    Chef::Log.info("stashed keystore_path: #{node['tomcat']['keystore_path']} ")
end

#If HTTPS and HTTP are disabled then warn the user that they may not be able to communicate with tomcat
if ((node['tomcat']['keystore_path'] == nil || node['tomcat']['keystore_path'].empty?) && (node['tomcat']['http_connector_enabled'] == nil || node['tomcat']['http_connector_enabled']=='false'))
  Chef::Log.warn("HTTP and HTTPS are disabled, this may result in no communication to the tomcat instance.")
end

#If HTTPS is enabled by adding a certificate and keystore, define the TLS protcols allowed.
#If HTTPS is enabled and the user manually disabled all TLS protocols from the UI, TLSv1.2 is enabled.
if (node['tomcat']['keystore_path'] != nil  && !node['tomcat']['keystore_path'].empty?)
  node.set['tomcat']['connector']['ssl_configured_protocols'] = ""
  if (node['tomcat']['tlsv1_protocol_enabled'] == 'true')
    node.set['tomcat']['connector']['ssl_configured_protocols'].concat("TLSv1,")
  end
  if (node['tomcat']['tlsv11_protocol_enabled'] == 'true')
    node['tomcat']['connector']['ssl_configured_protocols'].concat("TLSv1.1,")
  end
  if (node['tomcat']['tlsv12_protocol_enabled'] == 'true')
    node['tomcat']['connector']['ssl_configured_protocols'].concat("TLSv1.2,")
  end
  node['tomcat']['connector']['ssl_configured_protocols'].chomp!(",")
  if (node['tomcat']['connector']['ssl_configured_protocols'] == "")
    Chef::Log.warn("HTTPS is enabled,but all TLS protocols were disabled.  Defaulting to TLSv1.2 only.")
    node.set['tomcat']['connector']['ssl_configured_protocols'] = "TLSv1.2"
  end
end

node.set['tomcat']['manager']['key'] = SecureRandom.base64(21)
