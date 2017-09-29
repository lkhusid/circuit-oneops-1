require File.expand_path('../../libraries/models/tenant_model', __FILE__)
require 'json'

service_lb = node[:workorder][:ci][:ciAttributes]
tenant = TenantModel.new(service_lb[:endpoint], service_lb[:tenant], service_lb[:username], service_lb[:password])

loadbalancer_request = LoadbalancerRequest.new(tenant)
loadbalancer_dao = LoadbalancerDao.new(loadbalancer_request)
status = loadbalancer_dao.status
if !status
  node.set['status_result'] = 'Error'
end
