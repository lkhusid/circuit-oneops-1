require 'fog/azurerm'

CIRCUIT_PATH = '/opt/oneops/inductor/circuit-oneops-1'.freeze
COOKBOOKS_PATH = "#{CIRCUIT_PATH}/components/cookbooks".freeze
AZURE_TESTS_PATH = "#{COOKBOOKS_PATH}/azuredns/test/integration/delete/serverspec/tests".freeze

(
  Dir.glob("#{COOKBOOKS_PATH}/azuredns/libraries/*.rb") +
  Dir.glob("#{COOKBOOKS_PATH}/azure_base/libraries/*.rb")
).each { |lib| require lib }

require "#{CIRCUIT_PATH}/components/spec_helper.rb"
require "#{COOKBOOKS_PATH}/azure_base/test/integration/spec_utils"

provider = SpecUtils.new($node).get_provider
if provider =~ /azure/
  require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"
  Dir.glob("#{AZURE_TESTS_PATH}/*.rb").each { |test| require test }
end
