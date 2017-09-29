#
# Cookbook Name:: presto_coordinator
# Recipe:: status
#
require 'rubygems'
require 'json'

nodes = node.workorder.payLoad.RequiresComputes
computeNodes = Array.new
nodes.each do |n|
    computeNodes.push(n)
end

# build presto_peers array with the ips of the computeNodes
presto_peers = Array.new
computeNodes.each do |n|
    peer_ip = [n[:ciAttributes][:dns_record]]
    presto_peers.push(peer_ip)
end

# sort the Array since we need the list to be in consistnet order for next step
presto_peers.sort!

coordinator_ip = ''
coordinator_fqdn = ''

Chef::Log.info("IP list of #{presto_peers} and node id of #{node.ipaddress}")

coordinator_ip = presto_peers[0][0]

# tmp file to store private key
fuuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join
presto_cache_path = '/tmp/presto'

directory presto_cache_path do
  owner 'presto'
  group 'presto'
  mode  '0755'
end

ssh_key_file = presto_cache_path + "/" + fuuid
file ssh_key_file do
  content node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]
  mode 0600
end

Chef::Log.info("Coordinator IP: #{coordinator_ip}")
Chef::Log.info("Checking Config")
ruby_block "update_master_location" do
    block do
        `sudo ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null #{prestoPeerIp} cat /etc/presto/config.properties`
    end
end

file ssh_key_file do
  action :delete
end

Chef::Log.info("Execution completed")
