default['mirrormaker'][:rpm_dir] = "/mirrormaker/rpm"
default['mirrormaker'][:init_dir] = '/etc/init.d'
default['mirrormaker'][:log_dir] = "/mirrormaker/log"

default['mirrormaker'][:group] = 'mirrormaker'
default['mirrormaker'][:user] = 'mirrormaker'
 
default['mirrormaker'][:config_dir] = '/mirrormaker/config'
default['mirrormaker'][:consumer_config_dir] = '/mirrormaker/config'
default['mirrormaker'][:producer_config_dir] = '/mirrormaker/config'


default['mirrormaker']['jmx_port'] = '11061'
