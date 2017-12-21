# Cassandra drain. nodetool drain is a recommended to run before upgrading any node to make sure all memtables are flushed from the node to SSTables on disk.

cassandra_home = "/app/cassandra"
cassandra_current = "#{cassandra_home}/current"
Chef::Log.info("Running nodetool drain. Will timeout after 10 minutes")
Chef::Log.info("Cassandra Current is: #{cassandra_current}")

execute 'nodetool drain' do
  command "#{cassandra_current}/bin/nodetool drain"
  timeout 600
end
