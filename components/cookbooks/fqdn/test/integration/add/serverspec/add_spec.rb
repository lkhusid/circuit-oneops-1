require 'fog/azurerm'

CIRCUIT_PATH = '/opt/oneops/inductor/circuit-oneops-1'.freeze
COOKBOOKS_PATH = "#{CIRCUIT_PATH}/components/cookbooks".freeze
AZURE_TESTS_PATH = "#{COOKBOOKS_PATH}/azuredns/test/integration/add/serverspec/tests".freeze

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

cloud_name = $node['workorder']['cloud']['ciName']

priority = $node['workorder']['cloud']['ciAttributes']['priority']

metadata = $node['workorder']['payLoad']['RequiresComputes'][0]['ciBaseAttributes']['metadata'].nil? ?  $node['workorder']['payLoad']['RequiresComputes'][0]['ciAttributes']['metadata'] :  $node['workorder']['payLoad']['RequiresComputes'][0]['ciBaseAttributes']['metadata']
metadata_obj= JSON.parse(metadata)
org = metadata_obj['organization']
assembly = metadata_obj['assembly']
platform = metadata_obj['platform']
env = metadata_obj['environment']
domain = defined?($node['workorder']['payLoad']['remotedns'][0]['ciAttributes']['zone']) ? $node['workorder']['payLoad']['remotedns'][0]['ciAttributes']['zone'] :  $node['workorder']['services']['dns'][cloud_name]['ciAttributes']['zone']

is_azure = cloud_name =~ /azure/ ? true : false

fqdn = (platform+"."+env+"."+assembly+"."+org+"."+domain).downcase
command_execute = "host "+fqdn


describe "FQDN on azure" do
  context "FQDN entry" do
    it "should exist" do
      entries = `#{command_execute}`
      expect(entries).not_to be_nil
    end
  end


  if is_azure
    cloud = cloud_name.split("-")[1]

    if $node['workorder']['payLoad'].has_key?("lb")

      context "FQDN mapping with LB" do
        it "should exist" do
          if $node['workorder']['services'].has_key?("gdns") && $node['workorder']['services']['gdns'].has_key?(cloud_name)
            $node['workorder']['payLoad']['lb'].each do |service|
              ip = service['ciAttributes']['dns_record']
              if  priority == '1' && service['ciAttributes']['vnames'] =~ /#{cloud}/
                entries = `#{command_execute}`
                expect(entries).to include(ip) unless ip.nil?
              end
            end
          end
        end
      end


      context "FQDN not mapping with LB" do
        it "should not exist" do
          if $node['workorder']['services'].has_key?("gdns") && $node['workorder']['services']['gdns'].has_key?(cloud_name)
            $node['workorder']['payLoad']['lb'].each do |service|
              ip = service['ciAttributes']['dns_record']
              if  priority == '2' && service['ciAttributes']['vnames'] =~ /#{cloud}/
                entries = `#{command_execute}`
                expect(entries).not_to include(ip) unless ip.nil?
              end
            end
          end
        end
      end
    end

  end
end
