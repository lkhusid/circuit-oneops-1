#
# Cookbook Name:: presto_coordinator
# Recipe:: select_new_coordinator
#

require 'rubygems'
require 'json'

require File.expand_path("../coordinator_helper.rb", __FILE__)

configName = node['app_name']
configNode = node[configName]

thisCiName = node.workorder.rfcCi.ciName
thisCloudId = cloudid_from_name(thisCiName)

# Validate the clouds
validate_clouds()

primaryCloudId = get_primary_cloud_id()

# Find the IP address of the coordinator
clusterCoord = nil
if node.workorder.payLoad.has_key?("coord1")
  clusterCoord = node.workorder.payLoad.coord1
elsif node.workorder.payLoad.has_key?("coord2")
  clusterCoord = node.workorder.payLoad.coord2
end

coordIP = nil

if !clusterCoord.nil?
  clusterCoord.each do |thisCoord|
    next if thisCoord[:ciAttributes][:private_ip].nil? || thisCoord[:ciAttributes][:private_ip].empty?

    if primaryCloudId == cloudid_from_name(thisCoord.ciName)
      # This is the coordinator for this cloud
      coordIP = thisCoord[:ciAttributes][:private_ip]
      Chef::Log.debug("Found coordinator IP: #{coordIP}")
    end
  end
end

coordinator = is_coord_compute()

if coordinator
  # When the compute is a coordinator compute, the local IP address
  # is always the coordinator IP
  coordIP = node.ipaddress
end

Chef::Log.info("Coordinator IP will be #{coordIP} with node ip of #{node.ipaddress}")

file "/etc/presto/presto.coordinator" do
  content coordIP
  mode    '0644'
  owner   "presto"
  group   "presto"
end

cloud_name=node.workorder.cloud.ciName
platformName=node.workorder.box.ciName
customer_domain=node.customer_domain
subdomain=node.workorder.payLoad.Environment[0].ciAttributes["subdomain"]
zone_domain=node.workorder.services.dns[cloud_name].ciAttributes.zone

coordinator_fqdn="#{platformName}.#{subdomain}.#{zone_domain}"
#coordinator_fqdn="#{platformName}.#{customer_domain}"
certificate_dns=coordinator_fqdn

Chef::Log.info("Coordinator FQDN: #{coordinator_fqdn}")

thisCiClass = "bom.oneops.1." + configName.slice(0,1).capitalize + configName.slice(1..-1)
dependentCiClass = thisCiClass.sub('Presto-coordinator', 'Presto')

# Determine the http port.  This is in the Presto configuration, which this component
# depends on.  Find the dependent configuration to read the value.
http_port = '8080'
https_port = '8443'
enable_ssl = false
ldap_server = ''
ldap_domain = ''

presto_configs=node.workorder.payLoad.DependsOn.reject{ |d| d['ciClassName'] != dependentCiClass }
if (!presto_configs.nil? && !presto_configs[0].nil?)
  # The dependent configuration was found.
  presto_config = presto_configs[0][:ciAttributes]
  if presto_config.has_key?("http_port")
    http_port = presto_config["http_port"]
  end
  if presto_config.has_key?("https_port")
    https_port = presto_config["https_port"]
  end
  if presto_config.has_key?('enable_ssl') && (presto_config['enable_ssl'] != nil) && (presto_config['enable_ssl'] != "") && (presto_config['enable_ssl'] == 'true')
    enable_ssl = true
  end
  if presto_config.has_key?("presto_ldap_server")
    ldap_server = presto_config["presto_ldap_server"]
  end
  if presto_config.has_key?("presto_ldap_domain")
    ldap_domain = presto_config["presto_ldap_domain"]
  end
end

# General component names
orgName=node.workorder.payLoad.Organization[0].ciName
assemblyName=node.workorder.payLoad.Assembly[0].ciName
envName=node.workorder.payLoad.Environment[0].ciName

# Generate a keystore for SSL communication
o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
keystore_password = (0...50).map { o[rand(o.length)] }.join

keystore_dir="/etc/presto/keystore"
keystore_file="/etc/presto/keystore/presto_keystore.jks"
keystore_password_file="/etc/presto/keystore/keystore_pass"
coord_dn="CN=presto-coordinator, OU=#{envName}, OU=#{assemblyName}, O=#{orgName}"

# Make sure the keystore directory exists
directory "#{keystore_dir}" do
    owner "presto"
    group "presto"
    mode  '0755'
    action :create
end

# Read the password if it has already been generated.
if File::exist?("#{keystore_password_file}")
  keystore_password=File.read(keystore_password_file)
end

# Generate the password if it has not been created.
bash "generate_password" do
  user "root"
  code "echo #{keystore_password} > #{keystore_password_file}"
  creates "#{keystore_password_file}"
end

Chef::Log.info("keytool command: keytool -genkeypair -alias presto -keyalg RSA -keystore \"#{keystore_file}\" -storepass:file \"#{keystore_password_file}\" -dname \"#{coord_dn}\" -keypass \"#{keystore_password}\" -ext \"san=dns:#{certificate_dns},ip:#{node.ipaddress}\"")

# Create the keystore
bash "create_keystore" do
  user "root"
  code <<-EOF
    keytool -genkeypair -alias presto -keyalg RSA -keystore "#{keystore_file}" -storepass:file "#{keystore_password_file}" -dname "#{coord_dn}" -keypass "#{keystore_password}" -ext "san=dns:#{certificate_dns},ip:#{node.ipaddress}"
  EOF
  creates keystore_file
end

ldap_cert_file=Chef::Config[:file_cache_path] + "/ldap_cert.txt"

# Get the LDAP Certificate
bash "read_ldap_cert" do
  user "root"
  code <<-EOF
    openssl s_client -connect "#{ldap_server}:636" </dev/null 2>/dev/null |openssl x509 -outform PEM > #{ldap_cert_file}
  EOF
end

# Import the LDAP Certificate
bash "import_ldap_cert" do
  user "root"
  code <<-EOF
    CERT_COUNT="`keytool -list -keystore /usr/java/default/jre/lib/security/cacerts -storepass changeit |grep ldap_server |wc -l`"
    echo $CERT_COUNT > /tmp/cert_count.txt
    if [[ "$CERT_COUNT" == "0" ]]; then
      echo "[$CERT_COUNT] Adding cert" >> /tmp/cert_count.txt
      keytool -importcert -keystore /usr/java/default/jre/lib/security/cacerts -storepass changeit -noprompt -trustcacerts -alias ldap_server -file "#{ldap_cert_file}" > /tmp/cert_add.txt
    else
      echo "[$CERT_COUNT] NOT adding cert" >> /tmp/cert_count.txt
    fi
  EOF
end

template '/etc/presto/config.properties' do
    source 'config.properties.erb'
    owner 'presto'
    group 'presto'
    mode '0755'
    variables ({
        :coordinator => coordinator,
        :http_port => http_port,
        :coordinator_fqdn => coordinator_fqdn,
        :coordinator_ip => coordIP,
        :include_coordinator => configNode['include_coordinator'],
        :https_port => https_port,
        :keystore_file => keystore_file,
        :keystore_password => keystore_password,
        :enable_ssl => enable_ssl,
        :ldap_server => ldap_server,
        :ldap_domain => ldap_domain
    })
end

template '/usr/local/bin/presto-cli' do
    source 'presto-cli.erb'
    owner 'root'
    group 'root'
    mode '0555'
    variables ({
        :port => enable_ssl ? https_port : http_port,
        :coordinator_fqdn => coordinator ? coordIP : coordinator_fqdn,
        :enable_ssl => enable_ssl
    })
end

template '/usr/lib/presto/update-coordinator-ip.sh' do
    source 'update-coordinator-ip.sh.erb'
    owner 'root'
    group 'root'
    mode '0555'
    variables ({
        :http_port => http_port,
        :https_port => https_port,
        :coordinator_fqdn => coordinator_fqdn,
        :enable_ssl => enable_ssl
    })
end

ruby_block 'Restart presto service' do
    block do
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        shell_out!('service presto stop || true',
                   live_stream: Chef::Log.logger)
        shell_out!('ps -o pid -u presto | xargs kill -1 || true',
                   live_stream: Chef::Log.logger)
        shell_out!('service presto start',
                   live_stream: Chef::Log.logger)
    end
end
