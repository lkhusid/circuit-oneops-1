
cloud_name = node.workorder.cloud.ciName
dns_service = nil
if !node.workorder.services["slb"].nil? &&
    !node.workorder.services["slb"][cloud_name].nil?
  dns_service = node.workorder.services["dns"][cloud_name]
end
assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
org_name = node.workorder.payLoad.Organization[0]["ciName"]
platform_name = node.workorder.box.ciName
env_name = node.workorder.payLoad.Environment[0]["ciName"]
dns_zone = dns_service[:ciAttributes][:zone]
gslb_site_dns_id = node.workorder.services["slb"][cloud_name][:ciAttributes][:gslb_site_dns_id]

ci = {}
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
else
  ci = node.workorder.ci
end

node.set["lb_name"] = [platform_name, env_name, assembly_name, org_name, gslb_site_dns_id, dns_zone].join(".") +'-' + ci[:ciId].to_s + "-lb"

