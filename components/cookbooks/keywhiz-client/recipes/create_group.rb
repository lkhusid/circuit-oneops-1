require 'rubygems'
require 'net/https'
require 'json'

group = "/" + node[:oneops_server] + "/" + node.org + "/" + node.assembly + "/" + node.env
group = group.downcase

oneops_host = node.mgmt_url
https = node.kw_https
common_name = node.common_name
response = ""

https.start do |https|
  request = Net::HTTP::Post.new('/automation/v2/groups', 'Content-Type' => 'application/json')
  request.body = {:name => "#{group}", :description => "#{oneops_host}"}.to_json
  Chef::Log.info("Keywhiz create-group request => " + request.body)
  response = https.request(request)
end

Chef::Log.info("Keywhiz create-group Service response: " + response.body)

if response.code == '201'
  Chef::Log.info("group created successfully on server !")
elsif response.code == '409'
  Chef::Log.info("group already exists on server !")
else
  Chef::Log.error("group create request failed. Keywhiz server response code: " + response.code + " response body: " + response.body)

  #delete/cleanup the client cert from user's compute
  file '/opt/oneops/keywhiz/kw-client.cert' do
    action :delete
  end

  exit 1
end

https.start do |https|
  request = Net::HTTP::Post.new('/automation/v2/clients', 'Content-Type' => 'application/json')
  request.body = {:name => "#{common_name}", :groups => ["#{group}"], :description => "#{oneops_host}"}.to_json
  Chef::Log.info("Keywhiz create-client request => " + request.body)
  response = https.request(request)
end

Chef::Log.info("Keywhiz create-client Service response: " + response.body)

if response.code == '201'
  Chef::Log.info("client created successfully on server !")
elsif response.code == '409'
  Chef::Log.info("client already exists on server !")
else
  Chef::Log.error("client create request failed. Keywhiz server response code: " + response.code + " response body: " + response.body)

  #delete/cleanup the client cert from user's compute
  file '/opt/oneops/keywhiz/kw-client.cert' do
    action :delete
  end

  exit 1
end

file '/opt/oneops/keywhiz/kw-client.cert' do
  action :delete
end


