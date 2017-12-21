cassandra_home = node.default[:cassandra_home]
template "/home/cassandra/.bash_profile" do
  source "bash_profile.erb"
  owner "cassandra"
  group "cassandra"
  action :create
  # variables({
  #   :cassandra_home => cassandra_home
  # })
end
