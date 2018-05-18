# Cookbook Name:: keyspace
# Recipe:: add
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

ip = node.workorder.payLoad.ManagedVia[0][:ciAttributes][:dns_record].split(',')[0]

create_keyspace_file = "/tmp/"+node.workorder.rfcCi.ciId.to_s

dc_map = Keyspace::Util.find_dc_replication_factor(node)
and_clause = ""

case node.keyspace.placement_strategy
when "SimpleStrategy"
  and_clause = "WITH replication = {'class': 'SimpleStrategy', 'replication_factor': #{node.keyspace.replication_factor} }"
when "NetworkTopologyStrategy"
  and_clause = "WITH replication = {'class': 'NetworkTopologyStrategy', "
  dc_count = 0
  dc_map.keys.each do |dc|
    if dc_count > 0
      and_clause += ", "
    end
    and_clause += "'#{dc}': '#{node.keyspace.replication_factor}'"
    dc_count += 1
  end
  and_clause += "}"
end

node.set["and_clause"] = and_clause
node.set["cql_action"] = Keyspace::Util.keyspace_exists?(node, node.keyspace.keyspace_name.downcase) ? "ALTER" : "CREATE"

template create_keyspace_file do
  source "create_keyspace.erb"
end

execute "/opt/cassandra/bin/cqlsh #{ip} -u '#{node.workorder.payLoad.Keyspace_Cassandra[0][:ciAttributes].username}' -p '#{node.workorder.payLoad.Keyspace_Cassandra[0][:ciAttributes].password}' -f #{create_keyspace_file}" do
  sensitive true
  returns [0]
end

