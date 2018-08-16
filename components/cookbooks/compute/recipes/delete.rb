#
# Cookbook Name:: compute
# Recipe:: delete
#
# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "compute::node_lookup"
include_recipe "shared::set_provider_new"

Chef::Log.info("compute::delete -- name: #{node[:server_name]}")

if node[:provider_class] =~ /vagrant|virtualbox|docker|lxd/
  include_recipe "compute::del_node_#{node[:provider_class]}"
elsif node[:provider_class] =~ /azure/
  include_recipe 'azure::del_node'
elsif node[:provider_class] =~ /vsphere/
  include_recipe 'vsphere::del_node'
else
  include_recipe "compute::del_node_fog"
end

def get_records(record_type,ipaddress)
  return node.infoblox_conn.request(:method => :get, :path => "/wapi/v1.0/record:#{record_type}?ipv4addr=#{ipaddress}")
end

def delete_record(record_ref)
  res = node.infoblox_conn.request(:method => :delete, :path => "/wapi/v1.0/#{record_ref}")
  return res[:status]
end

delete_vm_ip = node[:workorder][:rfcCi][:ciAttributes][:dns_record]
cloud_name = node[:workorder][:cloud][:ciName]
provider_service = node[:workorder][:services][:dns][cloud_name][:ciClassName].split(".").last.downcase

# Support only infoblox cleanup
if provider_service.eql?("infoblox")
  include_recipe "fqdn::get_infoblox_connection"

  ["ptr","a"].each do |dns_type|

    res = get_records(dns_type,delete_vm_ip)

    unless res[:status] == 200
      # we are unable to check against infoblox
      # we should warn user that record still may existed.
      Chef::Log.warn("Unable to verify if record type #{dns_type} for #{delete_vm_ip} still existed")
    end

    records = JSON.parse(res[:body])

    Chef::Log.info("No records found type #{dns_type} for #{delete_vm_ip}") if records.size == 0
    
    records.each do |record|
      record_value = ""
      case dns_type
      when "ptr"
        record_value = "ref => #{record['_ref']}, ptrdname => #{record['ptrdname']}"
      when "a"
        record_value = "ref => #{record['_ref']}, name => #{record['name']}"
      end

      Chef::Log.info("Found record :: #{record_value}")

      res_delete = delete_record(record["_ref"])

      delete_status = (res_delete == 200) ? "success" : "failure"

      if delete_status.eql?("success")
        Chef::Log.info("Sucessfully remove record #{record["_ref"]}")
      else
        Chef::Log.warn("Failed to remove record #{record["_ref"]}")
      end

      puts "***TAG:compute_dns_delete=#{delete_status},#{record_value},#{delete_vm_ip},#{record["_ref"]}"
    end
  end
end
