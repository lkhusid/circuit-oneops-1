require File.expand_path('../../libraries/virtual_machine_manager', __FILE__)
require File.expand_path('../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../libraries/drs_rule_manager', __FILE__)

nsPathParts = node[:workorder][:rfcCi][:nsPath].split('/')
org = nsPathParts[1]
assembly = nsPathParts[2]
environment = nsPathParts[3]
platform_ci_id = node[:workorder][:box][:ciId]

cloud_name = node[:workorder][:cloud][:ciName]
service_compute = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

Chef::Log.info("Connecting to vCenter " + service_compute[:endpoint].to_s)
Chef::Log.info("Data Center " + service_compute[:datacenter].to_s)
Chef::Log.info("Cluster " + service_compute[:cluster].to_s)
tenant_model = TenantModel.new(service_compute[:endpoint], service_compute[:username], service_compute[:password], service_compute[:vsphere_pubkey])
compute_provider = tenant_model.get_compute_provider

Chef::Log.info("Searching for VM ..... " + node[:server_name].to_s)
start_time = Time.now
Chef::Log.info("start time " + start_time.to_s)
public_key = node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:public]
virtual_machine_manager = VirtualMachineManager.new(compute_provider, public_key, node[:server_name])
if !virtual_machine_manager.instance_id.nil?
  virtual_machine_manager.delete
else
  Chef::Log.warn("VM Not Found")
end
Chef::Log.info("end time " + Time.now.to_s)
total_time = Time.now - start_time
Chef::Log.info("Total time" + total_time.to_s)

drs_rule_manager = DrsRuleManager.new(compute_provider, service_compute)
instance_index = node[:workorder][:rfcCi][:ciName].split("-").last.to_i + platform_ci_id
availability_zones = drs_rule_manager.availability_zones
index = instance_index % availability_zones.size
vmgroup_name = org[0..15] + '_' + assembly[0..15] + '_' + platform_ci_id.to_s + '_' + environment[0..15] + '_' + availability_zones[index]
drs_rule_manager.remove_drs_rules(vmgroup_name)

Chef::Log.info("Exiting vSphere del_node ")
