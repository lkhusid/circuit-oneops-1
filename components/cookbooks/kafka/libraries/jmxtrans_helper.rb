def land_graphite_jmx_conf(graphite_host)
  assembly_name = node.workorder.payLoad.Assembly[0]["ciName"]
  org_name = node.workorder.payLoad.Organization[0]["ciName"]
  env_name = node.workorder.payLoad.Environment[0]["ciName"]

  jmx_kafka_variables = {
    :host       => graphite_host.split(":")[0],
    :port       => graphite_host.split(":")[1],
    :graphite_prefix   => "df.kafka.#{org_name}_#{assembly_name}_#{env_name}",
  }
  template_source = "jmx_graphite_kafka.json.erb"

  template "/var/lib/jmxtrans/kafka_graphite.json" do
    source template_source
    owner  'root'
    group  'root'
    mode   '0644'
    variables jmx_kafka_variables
    notifies :restart, "service[jmxtrans]"
  end
end
