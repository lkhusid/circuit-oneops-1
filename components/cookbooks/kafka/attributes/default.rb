default['kafka']['use_ptr'] = true

########################
# general zookeeper
########################

# default zookeeper log dir
default['kafka']['zk_syslog_dir'] = '/var/log/zk'

# default config dir
default['kafka']['zk_config_dir'] = '/etc/kafka'

# base zookeeper dir
default['kafka']['zk_install_dir'] = '/kafka/zookeeper'

# zookeeper jvm heap for systems with < 5G total mem
default['kafka']['zk_heap_size']['lt_5G'] = '512M'

# zookeeper jvm heap for systems with 5G < total mem < 9G
default['kafka']['zk_heap_size']['lt_9G'] = '1G'

# zookeeper jvm heap for systems with 9G < total mem < 17G
default['kafka']['zk_heap_size']['lt_17G'] = '3G'

# zookeeper jvm heap for systems with 17G < total mem
# value is intentionally set same as above range.
# this is basically a place holder in case we want to
# increase for larger systems in the future
default['kafka']['zk_heap_size']['default'] = '3G'

default['kafka']['zk_quorum_port'] = '2888'
default['kafka']['zk_election_port'] = '3888'

default['kafka']['zk_quorum_size'] = '3'

default['kafka']['kafka_jmx_port'] = '11061'

default['kafka']['zookeeper_jmx_port'] = '11063'


########################
# general kafka broker
########################

# default kafka user
default['kafka']['user'] = 'kafka'
default['kafka']['data_dir'] = '/kafka/logs'

# default kafka log dir
default['kafka']['syslog_dir'] = '/var/log/kafka'

# default config dir
default['kafka']['config_dir'] = '/etc/kafka'

# retention days of Kafka server logs
default['kafka']['kafka_server_log_retention_days'] = '7'

default['kafka']['restart_failed'] = false
default['kafka']['restart_failed_time'] = ""

default['kafka']['start_coordination']['recipe'] = 'kafka::rolling_restart'

default['kafka']['rolling_restart_max_tries'] = '100'

default['kafka']['rolling_restart_sleep_time'] = '5'

default['kafka']['rolling_restart_trigger'] = '1'

default['kafka']['zk_quorum_size'] = '3'


########################
# additional packages
########################

# jmxtrans 253
default['kafka']['jmxtrans']['rpm'] = 'jmxtrans-253.rpm'

# kafka gem
default['kafka']['gem']['rpm'] = 'kafka-gem-1.0.noarch.rpm'
