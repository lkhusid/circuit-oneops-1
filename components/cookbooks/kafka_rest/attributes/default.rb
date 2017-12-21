default['kafka_rest'][:log_dir] = '/var/log/kafka-rest'

default['kafka_rest'][:port] = '8082'

default['kafka_rest'][:jmx_port] = '7199'

default['kafka_rest'][:group] = 'kafkarest'

default['kafka_rest'][:user] = 'kafkarest'

default['kafka_rest']['3.2.0']['packages'] = ['confluent-common:confluent-common-3.2.0-1.noarch.rpm', 'confluent-rest-utils:confluent-rest-utils-3.2.0-1.noarch.rpm', 'confluent-kafka-rest:confluent-kafka-rest-3.2.0-1.noarch.rpm']
