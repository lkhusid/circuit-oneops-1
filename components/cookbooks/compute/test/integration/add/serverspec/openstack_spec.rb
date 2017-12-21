require "/opt/oneops/inductor/circuit-oneops-1/components/spec_helper.rb"
require 'fog'

cloud_name = $node['workorder']['cloud']['ciName']
provider = $node['workorder']['services']['compute'][cloud_name]['ciClassName'].gsub("cloud.service.","").downcase.split(".").last

if provider =~ /openstack/i
  compute_service = $node['workorder']['services']['compute'][cloud_name]['ciAttributes']
  rfcCi = $node['workorder']['rfcCi']
  nsPathParts = rfcCi['nsPath'].split("/")
  server_name = $node['workorder']['box']['ciName']+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi['ciId'].to_s

  # connect to openstack client
  conn = Fog::Compute.new({
                              :provider => 'OpenStack',
                              :openstack_api_key => compute_service['password'],
                              :openstack_username => compute_service['username'],
                              :openstack_tenant => compute_service['tenant'],
                              :openstack_auth_url => compute_service['endpoint']
                          })
  server = nil

  # Find your compute
  conn.servers.all.each do |i|
    if i.name == server_name
      server = i
      break
    end
  end

  server_metadata = server.metadata.to_hash
  describe "Compute connection" do
    it "Should exist" do
      expect(server.nil?).to be == false
    end
  end
  describe "Compute", :if => !server.nil? do
    it "Should be in state ACTIVE" do
      expect(server.state).to be == "ACTIVE"
    end
    it "Platform should be #{nsPathParts[5]}" do
      expect(server_metadata['platform']).to be == nsPathParts[5]
    end
    it "Management url should be #{$node['mgmt_url']}" do
      expect(server_metadata['mgmt_url']).to be == $node['mgmt_url']
    end
    it "Organization should be #{$node['workorder']['payLoad']['Organization'][0]['ciName'].to_s}" do
      expect(server_metadata['organization']).to be == $node['workorder']['payLoad']['Organization'][0]['ciName'].to_s
    end
    it "Component should be #{$node['workorder']['payLoad']['RealizedAs'][0]['ciId'].to_s}" do
      expect(server_metadata['component']).to be == $node['workorder']['payLoad']['RealizedAs'][0]['ciId'].to_s
    end
    it "Environment should be #{nsPathParts[3]}" do
      expect(server_metadata['environment']).to be == nsPathParts[3]
    end
    it "Assembly should be #{nsPathParts[3]}" do
      expect(server_metadata['assembly']).to be == nsPathParts[2]
    end
    it "Instance should be #{rfcCi['ciId']}" do
      expect(server_metadata['instance'].to_i).to be == rfcCi['ciId'].to_i
    end
  end
end
