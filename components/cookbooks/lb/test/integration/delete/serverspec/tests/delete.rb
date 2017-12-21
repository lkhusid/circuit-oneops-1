require 'excon'
require 'pp'

cloud_name = $node['workorder']['cloud']['ciName']
lb_service_type = $node['lb']['lb_service_type']
gslb_site_dns_id = nil
ciId = $node['workorder']['box']['ciId']
cloud_service = nil

if !$node['workorder']['services'][lb_service_type].nil? &&
    !$node['workorder']['services'][lb_service_type][cloud_name].nil?

  cloud_service = $node['workorder']['services'][lb_service_type][cloud_name]
  gslb_site_dns_id = cloud_service['ciAttributes']['gslb_site_dns_id']
  dns_service = $node['workorder']['services']['dns'][cloud_name]

end

lb_name = nil
vnames_map = {}

if $node['workorder']['rfcCi']['ciAttributes'].has_key?("vnames")
  vnames_map = JSON.parse($node['workorder']['rfcCi']['ciAttributes']['vnames'])
end
vnames_map.keys.each do |key|
  if key =~ /#{gslb_site_dns_id}/
    lb_name = key
  end
end

context "LB name" do
  it "should not exist" do
    expect(lb_name).not_to be_nil
  end
end

dns_zone = dns_service['ciAttributes']['zone']
vsvc_vport = nil
servicetype = nil

if $node['workorder']['rfcCi'].has_key?('ciAttributes') &&
    $node['workorder']['rfcCi']['ciAttributes'].has_key?('listeners')

  JSON.parse($node['workorder']['rfcCi']['ciAttributes']['listeners']).each do |listener|
    servicetype = listener.split(" ")[2].upcase
    servicetype = "SSL" if servicetype == "HTTPS"
    vservicetype = listener.split(" ")[0].upcase
    vservicetype = "SSL" if vservicetype == "HTTPS"
    vsvc_vport = vservicetype+"_"+listener.split(" ")[1]
  end
end


host = cloud_service['ciAttributes']['host']

encoded = Base64.encode64("#{cloud_service['ciAttributes']['username']}:#{cloud_service['ciAttributes']['password']}").gsub("\n","")
conn = Excon.new(
    'https://'+host,
    :headers => {
        'Authorization' => "Basic #{encoded}",
        'Content-Type' => 'application/x-www-form-urlencoded'
    },
    :ssl_verify_peer => false)

resp_obj = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbvserver/#{lb_name}").body)

exists = resp_obj["message"] =~ /No such resource/ ? true : false

context "lbserver" do
  it "should not exist" do
    expect(exists).to eq(true)
  end
end

resp_obj = JSON.parse(conn.request(
    :method=>:get,
    :path=>"/nitro/v1/config/lbvserver_servicegroup_binding/#{lb_name}").body)

exists = resp_obj["message"] =~ /No such resource/ ? true : false

context "lbserver_servicegroup" do
  it "should not exist" do
    expect(exists).to eq(true)
  end
end


if lb_name =~ /SSL/ && lb_name !~ /BRIDGE/
  resp_obj = JSON.parse(conn.request(
      :method=>:get,
      :path=>"/nitro/v1/config/sslvserver_sslcertkey_binding/#{lb_name}").body)

  exists = resp_obj["message"] =~ /No such resource/ ? true : false

  context "SSL" do
    it "should exist" do
      expect(exists).to eq(true)
    end
  end
end