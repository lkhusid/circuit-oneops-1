#Jetty tar ball location
default[:jolokia_proxy][:version] = "9.3.10.v20160621"
default[:jolokia_proxy][:mirror] ="http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/"
default[:jolokia_proxy][:tgz_file]="jetty-distribution-#{jolokia_proxy[:version]}.tar.gz"
default[:jolokia_proxy][:jetty_download_location]="#{jolokia_proxy[:mirror]}/#{jolokia_proxy[:version]}/#{jolokia_proxy[:tgz_file]}"
default[:jolokia_proxy][:checksum]="c7526b5c6eb89ae0a4373d69d8f2f46aa1d3c361"
default[:jolokia_proxy][:untar_dir]="jetty-distribution-#{jolokia_proxy[:version]}"


#Jolokia war file location

default[:jolokia_proxy][:jolokia_war_version] = "1.3.3"
default[:jolokia_proxy][:jolokia_war_mirror] = "http://central.maven.org/maven2/org/jolokia/jolokia-war/"
default[:jolokia_proxy][:jolokia_war_file] = "jolokia-war-#{jolokia_proxy[:jolokia_war_version]}.war"
default[:jolokia_proxy][:jolokia_war_location] ="#{jolokia_proxy[:jolokia_war_mirror]}/#{jolokia_proxy[:jolokia_war_version]}/#{jolokia_proxy[:jolokia_war_file]}"
default[:jolokia_proxy][:jolokia_war_checksum]="f6e5786754116cc8e1e9261b2a117701747b1259"

# defalut logging location
default[:jolokia_proxy][:jalokia_log4j_location] = 'http://central.maven.org/maven2/log4j/log4j/1.2.17/log4j-1.2.17.jar'
default[:jolokia_proxy][:jalokia_slf4j_location] = 'http://central.maven.org/maven2/org/slf4j/slf4j-log4j12/1.7.21/slf4j-log4j12-1.7.21.jar'
default[:jolokia_proxy][:jalokia_slf4j_api_location] = 'http://central.maven.org/maven2/org/slf4j/slf4j-api/1.7.21/slf4j-api-1.7.21.jar'




#
# home dirs
#

default[:jolokia_proxy][:home_dir] = "/opt/metrics_collector"
default[:jolokia_proxy][:jetty_base_dir] ="#{jolokia_proxy[:home_dir]}/jetty_base" #Locatation of jetty base to deploy jolokia
default[:jolokia_proxy][:jetty_home_dir] ="#{jolokia_proxy[:home_dir]}/jetty_home"

# jetty base dir
default[:jolokia_proxy][:conf_dir] = "#{jolokia_proxy[:jetty_base_dir]}/etc"
default[:jolokia_proxy][:lib_dir] = "#{jolokia_proxy[:jetty_base_dir]}/lib"
default[:jolokia_proxy][:resources_dir] = "#{jolokia_proxy[:jetty_base_dir]}/resources"
default[:jolokia_proxy][:webapps_dir] = "#{jolokia_proxy[:jetty_base_dir]}/webapps"
default[:jolokia_proxy][:jetty_logs_dir] = ""
default[:jolokia_proxy][:requestlog_logs_dir] = "#{jolokia_proxy[:jetty_base_dir]}/logs"
default[:jolokia_proxy][:bind_host] = "127.0.0.1"
default[:jolokia_proxy][:bind_port] = "17330"


#user and groups
default[:jolokia_proxy][:user] = "app"
default[:jolokia_proxy][:group] = "app"

# SEVERE ERROR (highest value) WARNING INFO CONFIG FINE FINER FINEST (lowest value)
default[:jolokia_proxy][:log_level] = 'INFO'
default[:jolokia_proxy][:log_class] = 'org.eclipse.jetty.util.log.Slf4jLog'
default[:jolokia_proxy][:request_log_retaindays]="5"
default[:jolokia_proxy][:enable_requestlog_logging]="false"

# jetty conf

default[:jolokia_proxy][:add_confs] = []
default[:jolokia_proxy][:pid_dir] = "#{jolokia_proxy[:home_dir]}/pid"


#The default arguments to pass to jetty.-Djetty.http.port,-Djetty.http.host
default[:jolokia_proxy][:args] = []


# Extra options to pass to the JVM
default[:jolokia_proxy][:java_options] = []
#Java
default[:jolokia_proxy][:java_home] ="/usr/bin/java"