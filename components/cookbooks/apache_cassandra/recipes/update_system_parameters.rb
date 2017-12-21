cassandra_home = node.default[:cassandra_home]

=begin
template "#{cassandra_home}/update_security_conf.sh" do
  source "update_security_conf.sh.erb"
  owner "root"
  group "root"
  mode 0644
end
["* - memlock unlimited", "* - nofile 100000", "* - nproc 32768", "* - as unlimited"].each do |name|
  execute "update_security_conf" do
    command "sh update_security_conf.sh '#{name}'"
    cwd "#{cassandra_home}"
  end
end


=end
template "#{cassandra_home}/update_nproc.sh" do
  source "update_nproc.sh.erb"
  owner "cassandra"
  group "cassandra"
  mode 0644
end

template "#{cassandra_home}/update_sysctl.sh" do
  source "update_sysctl.sh.erb"
  owner "cassandra"
  group "cassandra"
  mode 0644
end


execute "update_nproc" do
  command "sh update_nproc.sh"
  cwd "#{cassandra_home}"
end

execute "update_sysctl" do
  command "sh update_sysctl.sh"
  cwd "#{cassandra_home}"
end

`sudo sysctl -p`
