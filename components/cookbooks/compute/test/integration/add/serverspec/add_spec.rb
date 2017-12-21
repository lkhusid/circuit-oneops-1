CIRCUIT_PATH="/opt/oneops/inductor/circuit-oneops-1"
COOKBOOKS_PATH="#{CIRCUIT_PATH}/components/cookbooks"
AZURE_TESTS_PATH="#{COOKBOOKS_PATH}/azure/test/integration/add/serverspec/tests"

require "#{CIRCUIT_PATH}/components/spec_helper.rb"
require "#{COOKBOOKS_PATH}/azure_base/test/integration/spec_utils"

provider = SpecUtils.new($node).get_provider
if provider =~ /azure/
  require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"
  Dir.glob("#{AZURE_TESTS_PATH}/*.rb").each {|tst| require tst}
end

