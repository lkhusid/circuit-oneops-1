require 'fog/azurerm'

CIRCUIT_PATH = '/opt/oneops/inductor/circuit-oneops-1'.freeze
COOKBOOKS_PATH = "#{CIRCUIT_PATH}/components/cookbooks".freeze

(
  Dir.glob("#{COOKBOOKS_PATH}/azuredns/libraries/*.rb") +
  Dir.glob("#{COOKBOOKS_PATH}/azure_base/libraries/*.rb")
).each { |lib| require lib }

require "#{CIRCUIT_PATH}/components/spec_helper.rb"
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"

# run the tests
tests = File.expand_path('tests', File.dirname(__FILE__))
Dir.glob("#{tests}/*.rb").each { |test| require test }
