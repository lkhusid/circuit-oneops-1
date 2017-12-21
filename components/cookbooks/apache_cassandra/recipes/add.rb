include_recipe "apache_cassandra::validate_config"

#include_recipe "apache_cassandra::python_install"

node.default[:cassandra_home] = "/app/cassandra"
cassandra_current = "#{node[:cassandra_home]}/current"
puts "cassandra_current = #{cassandra_current}"
case node.platform
  when "ubuntu"
    include_recipe "apache_cassandra::add_debian"
  when "redhat"
    include_recipe "apache_cassandra::add_redhat"
  when "centos"
    include_recipe "apache_cassandra::add_redhat"
  when "fedora"
    include_recipe "apache_cassandra::add_redhat"
  else
    Chef::Log.error("platform not supported yet")
end

# Update config directives after the add logic
include_recipe "apache_cassandra::config_directives"

include_recipe "apache_cassandra::log4j_directives"

unless File.exist?("/dev/lxd/sock")
  include_recipe "apache_cassandra::limits"
  include_recipe "apache_cassandra::update_system_parameters"
end

include_recipe "apache_cassandra::topology"

`echo "export PATH=$PATH:#{cassandra_current}/bin" > /etc/profile.d/oneops_cassandra.sh`

include_recipe "apache_cassandra::config_user_profile"

include_recipe "apache_cassandra::initial_startup"

execute "chmod a+rx /etc/init.d/cassandra"

include_recipe "apache_cassandra::config_monitor"

execute "Set CASSANDRA_HOME Ownership to Cassandra User" do
  command "chown -R cassandra:cassandra #{cassandra_current}"
end