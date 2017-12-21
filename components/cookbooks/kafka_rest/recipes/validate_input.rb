if (node['kafka_rest']['zookeeper_connect_url'] == "## Please specify the  zookeeper (server:port) connections ##")
    Chef::Application.fatal!("Zookeeper connection string is not set. ")
end

if (node['kafka_rest']['version'] == '3.2.0' && node['kafka_rest']['bootstrap_url'] == "## Please specify the  bootstrap (server:port) connections ##")
    Chef::Application.fatal!("Bootstrap connection string is not set.")
end