cassandra_home = node.default[:cassandra_home]
cassandra_current = "#{cassandra_home}/current"

directory "#{cassandra_home}" do
  owner "cassandra"
  group "cassandra"
  mode "0755"
  action :create
end

directory "#{cassandra_current}" do
  owner "cassandra"
  group "cassandra"
  mode "0755"
  action :create
end

directory "#{cassandra_current}/lib.so" do
  owner "cassandra"
  group "cassandra"
  mode "0755"
  action :create
end

directory "#{cassandra_home}/log" do
  owner "cassandra"
  group "cassandra"
  mode "0755"
  action :create
end

directory "/var/log/cassandra" do
  owner "cassandra"
  group "cassandra"
  mode "0755"
  action :create
end