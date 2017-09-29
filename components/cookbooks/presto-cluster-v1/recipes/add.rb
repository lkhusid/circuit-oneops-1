# Presto - Presto cluster level code.
#
# This recipe contains the code that is run at the cluster level
# in a Presto deployment.

Chef::Log.info("Running presto_cluster::add")

require File.expand_path("../cluster_helper.rb", __FILE__)

# Create a monitor script that will check the status of the
# Presto coordinator URL. Get the fqdn from the customer_domain
# attribute and the platform name.
platformName=node.workorder.box.ciName
customer_domain=node.customer_domain

coordinator_fqdn="#{platformName}.#{customer_domain}"

template "/opt/nagios/libexec/check_lb_http_status.sh" do
  source "check_lb_http_status.sh.erb"
  owner "root"
  group "root"
  mode 0755
  variables ({
    :fqdn => coordinator_fqdn
  })
end

thisCiName = node.workorder.rfcCi.ciName
thisCloudId = cloudid_from_name(thisCiName)

# Output the DNS record that the FQDN should be mapped to
clusterCoord = node.workorder.payLoad.clusterCoord
coordIP = nil

if !clusterCoord.nil?
  clusterCoord.each do |thisCoord|
    next if thisCoord[:ciAttributes][:private_ip].nil? || thisCoord[:ciAttributes][:private_ip].empty? || (thisCloudId != cloudid_from_name(thisCoord.ciName))

    # All nodes are worker nodes
    coordIP = thisCoord[:ciAttributes][:private_ip]
    Chef::Log.debug("Found coordinator IP: #{coordIP}")
  end
end

if coordIP != nil
  puts "***RESULT:dns_record=#{coordIP}"
end
