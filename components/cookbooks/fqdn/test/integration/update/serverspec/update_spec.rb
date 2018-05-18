require 'resolv'
require 'ipaddr'
require 'excon'

is_windows = ENV['OS'] == 'Windows_NT'

begin
  CIRCUIT_PATH = '/opt/oneops/inductor/circuit-oneops-1'
  COOKBOOKS_PATH = "#{CIRCUIT_PATH}/components/cookbooks".freeze
  require "#{CIRCUIT_PATH}/components/spec_helper.rb"
  require "#{COOKBOOKS_PATH}/fqdn/test/integration/library.rb"
rescue Exception =>e
  CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
  require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"
  require "/home/oneops/circuit-oneops-1/components/cookbooks/fqdn/test/integration/library.rb"
end

require "#{CIRCUIT_PATH}/components/cookbooks/fqdn/test/integration/add/serverspec/add_spec"
