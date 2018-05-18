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

lib = Library.new
entries = lib.build_entry_list
entries.each do |entry|
  dns_name = entry['name']
  dns_value = entry['values']

  dns_val = dns_value.is_a?(String) ? [dns_value] : dns_value

  if !dns_val.nil? && dns_val.size != 0
    dns_val.each do |value|
      flag = lib.check_record(dns_name, value)
      context "FQDN mapping" do
        it "should be deleted" do
          expect(flag).to eq(true)
        end
      end
    end
  end
end

cloud_name = $node['workorder']['cloud']['ciName']

depends_on_lb = false
$node['workorder']['payLoad']['DependsOn'].each do |dep|
  depends_on_lb = true if dep['ciClassName'] =~ /Lb/
end

env = $node['workorder']['payLoad']['Environment'][0]['ciAttributes']

gdns_service = nil
if $node['workorder']['services'].has_key?('gdns') &&
    $node['workorder']['services']['gdns'].has_key?(cloud_name)
  gdns_service = $node['workorder']['services']['gdns'][cloud_name]
end

if env.has_key?("global_dns") && env["global_dns"] == "true" && depends_on_lb &&
    !gdns_service.nil? && gdns_service["ciAttributes"]["gslb_authoritative_servers"] != '[]'

  cloud_service= nil
  cloud_name = $node['workorder']['cloud']['ciName']
  if $node['workorder']['services'].has_key?('lb')
    cloud_service = $node['workorder']['services']['lb'][cloud_name]['ciAttributes']
  else
    cloud_service = $node['workorder']['services']['gdns'][cloud_name]['ciAttributes']
  end


  host = $node['workorder']['services']['gdns'][cloud_name]['ciAttributes']['host']
  ci = $node['workorder']['box']
  gslb_service_name = lib.get_gslb_service_name
  conn = lib.gen_conn(cloud_service,host)

  resp_obj = JSON.parse(conn.request(
      :method => :get,
      :path => "/nitro/v1/config/gslbservice/#{gslb_service_name}").body)


  context "GSLB service name" do
    it "should not exist" do
      status = resp_obj["message"]
      expect(status).to eq("The GSLB service does not exist")
    end
  end


  gslb_service_name = lib.get_gslb_service_name_by_platform

  resp_obj = JSON.parse(conn.request(
      :method=>:get,
      :path=>"/nitro/v1/config/gslbservice/#{gslb_service_name}").body)

  context "GSLB service by platform" do
    it "should not exist" do
      status = resp_obj["message"]
      expect(status).to eq("The GSLB service does not exist")
    end
  end
end