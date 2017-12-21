# Repair - Repairs the Spark components.
#
# This recipe ensures that all of the Spark components are working
# properly.  In the event that any of them have been changed or are
# not functioning, they are set back to what they should be.

Chef::Log.info("Running #{node['app_name']}::repair")

# Stop the Spark services before the repair
include_recipe "#{node['app_name']}::spark_stop"

sparkInfo = get_spark_info()
is_spark_master = sparkInfo[:is_spark_master]
is_client_only = sparkInfo[:is_client_only]
configNode = sparkInfo[:config_node]

spark_dir = "#{configNode['spark_base']}/spark"

# Make sure all java instances for the Spark user are killed
bash "killall_java" do
    user "root"
    code <<-EOF
        killall -9 -u spark java
    EOF
    returns [0, 1]
end


if is_client_only && configNode.has_key?('enable_thriftserver') && (configNode['enable_thriftserver'] == 'true')
  # Check the keystore password status, and repair if necessary
  if node.workorder.has_key?("rfcCi")
    thisCiName = node.workorder.rfcCi.ciName
  else
    thisCiName = node.workorder.ci.ciName
  end

  hostname=`hostname | tr --delete '\n'`

  truststore_path="#{spark_dir}/conf/keystore/#{thisCiName}.truststore"
  truststore_pwd=`cat #{spark_dir}/conf/keystore/pub_truststore_pass | tr --delete '\n'`
  keystore_path="#{spark_dir}/conf/keystore/#{thisCiName}.keystore"
  keystore_pwd=`cat #{spark_dir}/conf/hive-site.xml |grep "hive.server2.keystore.password" -A 1 |grep value |sed "s/^ *<value>//" |sed "s|</value>||" | tr --delete '\n'`

  update_truststore_pwd=false
  update_hivesite=false

  if truststore_pwd.empty?
    Chef::Log.info("Trust store password could not be found...generating a new one.")

    # Generate a new password.  This shouldn't happen unless
    # the file has been removed.
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    truststore_pwd = (0...50).map { o[rand(o.length)] }.join

    update_truststore_pwd=true
  end

  if keystore_pwd.empty?
    Chef::Log.info("Keystore password could not be found...generating a new one.")

    # Generate a new password.  This shouldn't happen unless
    # the file has been modified.  This will cause the
    # hive-site.xml to need to be updated.
    o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    keystore_pwd = (0...50).map { o[rand(o.length)] }.join

    update_hivesite=true
  end

  # Fix the keystores if they are broken.  They must be generated
  # together.
  bash "fix_keystore" do
      user "spark"
      cwd "#{spark_dir}/conf/keystore"
      code <<-EOF
        CHECK_KEYSTORE=`keytool -list -keystore "#{keystore_path}" -storepass "#{keystore_pwd}" > /dev/null; echo $?`
        CHECK_TRUSTSTORE=`keytool -list -keystore "#{truststore_path}" -storepass #{truststore_pwd} > /dev/null; echo $?`

        if [[ "$CHECK_KEYSTORE" != "0" || "$CHECK_TRUSTSTORE" != "0" ]]; then
          rm -f #{keystore_path}
          rm -f #{truststore_path}
          /usr/bin/keytool -genkeypair -alias #{hostname} -keystore #{keystore_path} -keyalg "RSA" -keysize 4096 -dname "CN=$(hostname -f),O=Hadoop" -storepass #{keystore_pwd} -keypass #{keystore_pwd} -validity 365
          /usr/bin/keytool -exportcert -keystore #{keystore_path} -alias #{hostname} -storepass #{keystore_pwd} -file #{hostname}.cer
          /usr/bin/keytool -importcert -keystore #{truststore_path} -alias #{hostname} -storepass #{truststore_pwd} -file #{hostname}.cer -noprompt
          /bin/openssl x509 -inform DER -outform PEM -in #{hostname}.cer -out #{hostname}.pem
        fi
      EOF
  end

  # Update the hive-site.xml if a new keystore password
  # had to be generated.
  ruby_block "update_hive_site_xml" do
    block do
      origHiveSite = File.read("#{spark_dir}/conf/hive-site.xml")
      hiveSiteXML = Nokogiri::XML(origHiveSite)

      # hive.server2.keystore.password should be a password that is unique to Spark
      hiveSiteXML.xpath("/configuration/property[name[text()='hive.server2.keystore.password']]/value").each do |xmlNode|
        xmlNode.content = "#{keystore_pwd}"
      end

      # After the values are changed, write out the file.
      File.open("#{spark_dir}/conf/hive-site.xml", "w") do |newFile|
        newFile.write hiveSiteXML.to_xml
      end
    end
    only_if { update_hivesite }
  end

  # Update the truststore file if a new truststore password
  # had to be generated.
  file "#{spark_dir}/conf/keystore/pub_truststore_pass" do
    content "#{truststore_pwd}"
    owner "spark"
    group "spark"
    mode '0644'
    only_if { update_truststore_pwd }
  end
end

# Make sure the Spark master URL is correct
sparkMasterURL = "spark://"

allMasters = nil

if node.workorder.payLoad.has_key?("allMasters")
  allMasters = node.workorder.payLoad.allMasters
elsif node.workorder.payLoad.has_key?("sparkMasters")
  allMasters = node.workorder.payLoad.sparkMasters
end

if allMasters.nil?
  Chef::Log.warn("Unable to find Spark masters...can't repair spark.master")
else
  allMasters.each do |thisMaster|
    if !sparkMasterURL.end_with? "/"
      sparkMasterURL = sparkMasterURL + ","
    end

    sparkMasterURL = sparkMasterURL + thisMaster[:ciAttributes][:private_ip]

    # Use port 7077 as a default.  This would need to be read
    # from the configuration in case it becomes configurable
    sparkMasterURL = sparkMasterURL + ":7077"
  end

  file "#{spark_dir}/conf/spark.master" do
    content sparkMasterURL
    mode    '0644'
    owner   'spark'
    group   'spark'
  end
end

# Start the services
include_recipe "#{node['app_name']}::spark_start"

# Make sure the keys are all added to the oneops user
include_recipe "#{node['app_name']}::trust_pub_keys"
