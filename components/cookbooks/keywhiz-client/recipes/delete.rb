include_recipe "keywhiz-client::set_attributes"

https = node.kw_https
common_name = node.common_name
cloud_name = node[:workorder][:cloud][:ciName]
provider = ""
cert_service = node[:workorder][:services][:certificate]

if ! cert_service.nil? && ! cert_service[cloud_name].nil?
        provider = node[:workorder][:services][:certificate][cloud_name][:ciClassName].gsub("cloud.service.","").downcase.split(".").last
else
        Chef::Log.error("Certificate cloud service not defined for this cloud")
        exit 1
end

ci_id = node.workorder.rfcCi.ciId

# Stop and disable the keysync service
service "keysync" do
  supports :status => true, :restart => true
  action [:stop, :disable]
  only_if { File.exists?("/opt/oneops/keywhiz/keysync/keysync") }
end

# Now delete the keysync binding/entry on the keywhiz server
ruby_block "delete keywhiz client" do
  block do
    response = ""
    
    https.start do |https|
            request = Net::HTTP::Delete.new("/automation/v2/clients/#{common_name}", 'Content-Type' => 'application/json')
            Chef::Log.info("Keywhiz delete-client request for client name => " + "#{common_name}")
            response = https.request(request)
    end
    
    if ! response.body.nil?
    	Chef::Log.info("Keywhiz delete-client Service response: " + response.body)
    end
    
    if response.code == '200' || response.code == '204' || response.code == '404'
        Chef::Log.info("client deleted successfully on server ! Now deleting keywhiz directory")
    else
        msg = "client delete request failed. Keywhiz server response code: " + response.code
        puts "***FAULT:FATAL=#{msg}"
        Chef::Application.fatal!(msg)
    end
  end
  action :run
end

#Now delete the keysync cert

certificate = Hash.new
certificate["common_name"] = node[:common_name]
certificate["san"] = ""
certificate["domain"] = node[:keywhiz_sync_cert_domain]
certificate["owner_email"] = node[:keywhiz_sync_cert_owner_dl]
certificate["external"] = "false"
certificate["passphrase"] = node[:sync_cert_passphrase]

node.set[:certificate] = certificate

include_recipe provider + "::delete_certificate"

#do the other cleanup to delete the keysync
directory '/opt/oneops/keywhiz' do
        action :delete
        recursive true
end


