# skip if running in a container
execute "echo 'cassandra  -  memlock  unlimited'> /etc/security/limits.d/cassandra.conf" do
  not_if "dmesg | grep 'Initializing cgroup'"
end

execute "echo '*  -  memlock  unlimited'   >> /etc/security/limits.d/cassandra.conf"
execute "echo 'cassandra  -  nofile  100000'   >> /etc/security/limits.d/cassandra.conf"
execute "echo 'cassandra  -  nproc 32768'   >> /etc/security/limits.d/cassandra.conf"
execute "echo 'cassandra  -  as unlimited'   >> /etc/security/limits.d/cassandra.conf"

execute "echo '*  -  memlock  unlimited'   >> /etc/security/limits.conf"
execute "echo '*  -  nofile  100000'   >> /etc/security/limits.conf"
execute "echo '*  -  nproc 32768'   >> /etc/security/limits.conf"
execute "echo '*  -  as unlimited'   >> /etc/security/limits.conf"