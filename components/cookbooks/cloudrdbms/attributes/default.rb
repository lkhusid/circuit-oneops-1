#
# Cookbook Name:: cloudrdbms
# Attributes:: default.rb
#
default['cloudrdbms']['greeting'] = "Cloud RDBMS Installation";

# this below is where the install files will be downloaded from
default['cloudrdbms']['urlbase'] = 'http://gec-maven-nexus.walmart.com/nexus/content/repositories/thirdparty'
default['cloudrdbms']['runOnEnv'] = 'devDefaultValue'

# this below is where the artifact files will be downloaded from
default['cloudrdbms']['artifacturlbase'] = 'http://gec-maven-nexus.walmart.com/nexus/content/repositories/pangaea_releases/com/walmart/platform/mysql/mysql-agent'

#default zk version
default['cloudrdbms']['zookeeperversion'] = '3.5.3-beta'
