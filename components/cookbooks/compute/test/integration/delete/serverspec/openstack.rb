require "/opt/oneops/inductor/circuit-oneops-1/components/spec_helper.rb"
require 'fog'

cloud_name = $node['workorder']['cloud']['ciName']
provider = $node['workorder']['services']['compute'][cloud_name]['ciClassName'].gsub("cloud.service.","").downcase.split(".").last

if provider =~ /openstack/i
  compute_service = $node['workorder']['services']['compute'][cloud_name]['ciAttributes']
  rfcCi = $node["workorder"]["rfcCi"]
  nsPathParts = rfcCi["nsPath"].split("/")

  # TO-DO incapsulate server_name into a separate function.
  # Save in a library file and use for both compute recipes and KCI tests
  server_name = $node['workorder']['box']['ciName']+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi['ciId'].to_s
  if(server_name.size > 63)
    server_name = server_name.slice(0, 63 - rfcCi['ciId'].to_s.size - 1) +
      '-' + rfcCi['ciId'].to_s
  end

  # connect to openstack client
  domain = compute_service.key?('domain') ? compute_service[:domain] : 'default'

  conn = Fog::Compute.new({
    :provider => 'OpenStack',
    :openstack_api_key => compute_service[:password],
    :openstack_username => compute_service[:username],
    :openstack_tenant => compute_service[:tenant],
    :openstack_auth_url => compute_service[:endpoint],
    :openstack_project_name => compute_service[:tenant],
    :openstack_domain_name => domain
  })
    
  server = nil
  # Find your compute
  conn.servers.all.each do |i|
    if i.name == server_name
      server = i
      break
    end
  end

  describe "Openstack connection" do
    it "should not be nill" do
      expect(conn.nil?).to be == false
    end
  end
  describe "Compute connection", :if => !conn.nil? do
    it "should not exist" do
      expect(server.nil?).to be == true
    end
  end
end

