# Copyright 2018, Walmart Stores, Inc.
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

# Cookbook Name:: fqdn
# Recipe:: cleanup
#
# clean up dns record for entries that no longer
# valid.
# no ManagedVia - recipes will run on the gw

extend Fqdn::Base
Chef::Resource::RubyBlock.send(:include, Fqdn::Base)

def get_record_type (dns_values)
  record_type = "cname"
  ips = dns_values.grep(/\d+\.\d+\.\d+\.\d+/)
  if ips.size > 0
    record_type = "a"
  end
  return record_type
end


require 'excon'

# ex) customer_domain: env.asm.org.oneops.com
customer_domain = node[:customer_domain]
box_dns_name    = node[:workorder][:box][:ciName]
dns_name        = "#{box_dns_name}.#{customer_domain}".downcase
dns_record      = node[:workorder][:rfcCi][:ciAttributes][:public_ip]
cloud           = node[:workorder][:cloud][:ciName]
ns              = node[:ns]
service_attrs   = get_dns_service
primary_platform_dns_name = dns_name.split('.').select{|i| (i != service_attrs[:cloud_dns_id])}.join('.')

include_recipe "fqdn::get_infoblox_connection"

# delete / create dns entries
#
dns_type = get_record_type([dns_record])

[ dns_name, primary_platform_dns_name ].each do |entry|
  Chef::Log.info("delete #{dns_type}: #{entry} to #{dns_record}")

  infoblox_key = "ipv4addr"

  if dns_type == "cname"
    infoblox_key = "canonical"
  end

  # check for server
  record = { :name => entry, infoblox_key => dns_record }
  Chef::Log.info("record: #{record.inspect}")

  records = JSON.parse(node.infoblox_conn.request(
    :method=>:get,
    :path=>"/wapi/v1.0/record:#{dns_type}",
    :body => JSON.dump(record) ).body)

  if records.size == 0
    Chef::Log.info("record already deleted")
  else
    records.each do |r|
      ref = r["_ref"]
      if r["ipv4addr"].eql?(dns_record)
        resp = node.infoblox_conn.request(:method => :delete, :path => "/wapi/v1.0/#{ref}")
        Chef::Log.info("status: #{resp.status}")
        Chef::Log.info("response: #{resp.inspect}")
      end
    end
  end
end  	