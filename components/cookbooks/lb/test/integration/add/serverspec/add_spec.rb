CIRCUIT_PATH = '/opt/oneops/inductor/circuit-oneops-1'.freeze
COOKBOOKS_PATH = "#{CIRCUIT_PATH}/components/cookbooks".freeze

require "#{CIRCUIT_PATH}/components/spec_helper.rb"
require "#{COOKBOOKS_PATH}/azure_base/test/integration/spec_utils"
require "#{COOKBOOKS_PATH}/lb/test/integration/lb_spec_utils"

cloud_service = SpecUtils.new($node).get_cloud_service['ciClassName'].split('.').last.downcase
lb_spec_utils = LbSpecUtils.new($node)
lb_spec_utils.initialize_lb_name
if cloud_service =~ /azure_lb|azuregateway/
  require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"
end

#Run service provider specific tests
spec_file = File.join(
    COOKBOOKS_PATH,
    cloud_service,
    '/test/integration/add/serverspec/add_spec.rb')

require spec_file if File.file?(spec_file)