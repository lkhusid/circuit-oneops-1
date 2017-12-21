# telegraf - Set up Telegraf monitoring plugins
#
# This recipe installs all of the scripts used for
# monitoring through Telegraf.

Chef::Log.info("Running #{node['app_name']}::telegraf")

require 'json'

require File.expand_path("../spark_helper.rb", __FILE__)

package 'logcheck'

sparkInfo = get_spark_info()
is_spark_master = sparkInfo[:is_spark_master]
is_client_only = sparkInfo[:is_client_only]
configNode = sparkInfo[:config_node]

spark_base = configNode['spark_base']
spark_dir = "#{spark_base}/spark"

metrics_port = "8080"
metrics_path = "master/json/"

if !is_spark_master && !is_client_only
  # Change the port and path to the worker settings if this is a worker
  metrics_port = "8081"
  metrics_path = "json/"
end

sparkTelegraf = "#{spark_dir}/spark_telegraf.sh"
sparkTelegrafLog = "#{spark_dir}/spark_telegraf_log.sh"
sparkClusterTelegraf = "#{spark_dir}/spark_cluster_telegraf.sh"

# Create a template for the Spark metrics script
template sparkTelegraf do
    source "spark-telegraf.sh.erb"
    owner "spark"
    group "spark"
    mode "0755"
    variables ({
      :metrics_port => metrics_port,
      :metrics_path => metrics_path,
      :is_spark_master => is_spark_master
    })
  not_if { is_client_only }
end

template sparkTelegrafLog do
    source "spark-telegraf-log.sh.erb"
    owner "spark"
    group "spark"
    mode "0755"
    variables ({
      :is_spark_master => is_spark_master
    })
    not_if { is_client_only }
end

# Create a template for the Spark metrics script
template sparkClusterTelegraf do
    source "spark-cluster-telegraf.sh.erb"
    owner "spark"
    group "spark"
    mode "0755"
    variables ({
      :metrics_port => metrics_port,
      :metrics_path => metrics_path,
      :is_spark_master => is_spark_master
    })
  only_if { is_spark_master }
end

