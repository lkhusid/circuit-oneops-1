include_recipe "jolokia_proxy::stop"



#Delete jolokia_proxy Home DIR i.e. /app/metrics_collector

jolokia_proxy = "#{node[:jolokia_proxy][:home_dir]}"
log jolokia_proxy

directory jolokia_proxy  do
    owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
    recursive true
    action :delete
  end


#Delete jetty startup sctipt file


file "/etc//init.d/jolokia_proxy"  do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
  action :delete
end
  

  
  
  
#Delete jetty config file


file "/etc//default/jetty"  do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
  action :delete
end
 
  
  
#Delete jetty.conf file

file "/etc/jetty.conf"  do
  owner node.jolokia_proxy[:user] and group node.jolokia_proxy[:group] and mode 0755
  action :delete
end

