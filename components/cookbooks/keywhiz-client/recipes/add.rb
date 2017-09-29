require 'rubygems'
require 'net/https'
require 'json'

#directory '/opt/oneops/keywhiz' do
#	action :create
#end

`mkdir -p /opt/oneops/keywhiz`

include_recipe "keywhiz-client::set_attributes"

#call cert cookbook to provision cert
cloud_name = node[:workorder][:cloud][:ciName]
provider = ""
cert_service = node[:workorder][:services][:certificate]

if !cert_service.nil? && !cert_service[cloud_name].nil?
  provider = node[:workorder][:services][:certificate][cloud_name][:ciClassName].gsub("cloud.service.", "").downcase.split(".").last
else
  Chef::Log.error("Certificate cloud service not defined for this cloud")
  exit 1
end

ci_id = node.workorder.rfcCi.ciId

certificate = Hash.new
certificate["common_name"] = node[:common_name]
certificate["san"] = ""
certificate["external"] = "false"
certificate["domain"] = node[:keywhiz_sync_cert_domain]
certificate["owner_email"] = node[:keywhiz_sync_cert_owner_dl]
certificate["passphrase"] = node[:sync_cert_passphrase]

node.set[:certificate] = certificate
Chef::Log.info("common name will be: " + certificate["common_name"])
include_recipe provider + "::add_certificate"

#generate group-id on kw server
include_recipe "keywhiz-client::create_group"

#generate keywhiz-sync config 
include_recipe "keywhiz-client::create_sync"
