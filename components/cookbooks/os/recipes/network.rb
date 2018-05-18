Chef::Recipe.send(:include, NetworkHelper)
Chef::Resource.send(:include, NetworkHelper)
cloud_name = node[:workorder][:cloud][:ciName]
provider = node[:workorder][:services][:compute][cloud_name][:ciClassName].gsub('cloud.service.', '').downcase

_hosts = node['workorder']['rfcCi']['ciAttributes'].has_key?('hosts') ? JSON.parse(node['workorder']['rfcCi']['ciAttributes']['hosts']) : {}
_hosts.values.each do |ip|
  if ip !~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/
    Chef::Log.error("host value of: \"#{ip}\" is not an ip.  fix hosts map to have hostname then ip in the 2 fields.")

    puts "***FAULT:FATAL=invalid host ip #{ip} - check hosts attribute"
    e = Exception.new('no backtrace')
    e.set_backtrace('')
    raise e

  end
end

full_hostname = node[:full_hostname]
_hosts[full_hostname] = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["private_ip"]
compute_baremetal = node.workorder.payLoad.ManagedVia[0]["ciAttributes"]["is_baremetal"]

directory '/etc/cloud/cloud.cfg.d' do
  owner 'root'
  group 'root'
  mode '0664'
  recursive true
  action :create
end

file '/etc/cloud/cloud.cfg' do
  mode 0664
  owner 'root'
  group 'root'
  content ''
end

bash 'set-hostname' do
  code <<-EOH
  hostnamectl set-hostname #{node.vmhostname}
  printf "hostname: #{node.vmhostname}\nfqdn: #{full_hostname}\n" > /etc/cloud/cloud.cfg.d/99_hostname.cfg
  if grep -Fxq "preserve_hostname: true" /etc/cloud/cloud.cfg
  then
    echo "preserver hostname already set to true in /etc/cloud/cloud.cfg"
  else
    printf "preserve_hostname: true\n" >> /etc/cloud/cloud.cfg
  fi
EOH
  not_if { provider.include? 'docker' }
end

# update /etc/hosts
if !node['fast_image']
  gem_package 'ghost'
end

file '/tmp/hosts' do
  owner 'root'
  group 'root'
  mode 0755
  content _hosts.map {|e| e.join(' ') }.join("\n")
  action :create
end

bash 'update_hosts' do
  code <<-EOH
    ghost empty
    ghost import /tmp/hosts
  EOH
end

# add short hostname at the end of the FQDN entry line in /etc/hosts
ruby_block 'update /etc/hosts' do
  block do
    tmp_host = File.read('/etc/hosts')
    mod_host = tmp_host.gsub(full_hostname,full_hostname+' '+node.vmhostname)
    File.open('/tmp/etc_hosts', 'w') do |file|
        file.puts mod_host
    end

    Chef::Log.info('setting /etc/hosts')
    change_host = Mixlib::ShellOut.new('cat /tmp/etc_hosts > /etc/hosts')
    change_host.run_command
    Chef::Log.debug("Mod /etc/hosts stdout: #{change_host.stdout}")
    if !change_host.stderr.empty?
      Chef::Log.error("Mod /etc/hosts stderr: #{change_host.stderr}")
      change_host.error!
    end
  end
end

# bind install
if !node['fast_image']
  package 'Install bind' do
    case node['platform']
      when 'redhat', 'centos', 'fedora', 'suse'
        package_name 'bind'
      when 'ubuntu', 'debian'
        package_name 'bind9'
      else
        package_name 'named'
    end
    action :install
  end
end

customer_domain = trim_customer_domain(node)
customer_domains, customer_domains_dot_terminated = search_domains(node)

Chef::Log.info('adding /opt/oneops/domain... ')
file '/opt/oneops/domain' do
  mode 0644
  owner 'root'
  group 'root'
  content "#{customer_domain}\n"
end

if node['platform'] =~ /centos|redhat/
  file '/etc/named.conf' do
    content "include \"/etc/bind/named.conf.options\";\n"
  end
  %w[/etc/bind /var/cache/bind].each do |d|
    directory d do
      mode '0755'
      recursive true
    end
  end
end

if node['platform'] != 'ubuntu'
  file '/etc/sysconfig/named' do
    content 'OPTIONS="-4"'
  end
end

pkg = node['platform'] == 'suse' ? 'named.d' : 'bind'
template "/etc/#{pkg}/named.conf.options" do
  cookbook 'os'
  source 'named.conf.options.erb'
  variables(:forwarders => get_nameservers)
end

file '/etc/resolv.conf' do
  content "nameserver 8.8.4.4\n"
  only_if { ns = get_nameservers; ns.empty? && ns != '8.8.4.4' }
end

template "/etc/#{pkg}/named.conf.local" do
  cookbook 'os'
  source 'named.conf.local.erb'
  variables(
    lazy {
      {
        :zone_domain => trim_zone_domain(node['customer_domain']),
        :forwarders => authoritative_dns_ip(trim_zone_domain(node['customer_domain']))
      }
    }
  )
end

file '/etc/dhcp/dhclient.conf' do
  content "supersede domain-search #{customer_domains};\n" \
          "send host-name \"#{full_hostname}\";\n"
end

ruby_block 'setup bind and dhclient' do
  block do
    Chef::Log.info('*** SETUP BIND ***')

    # handle other config files such as /etc/dhcp/dhclient-eth0.conf
    # these shall be linked to dhclient.conf
    Chef::Log.info('symlink any dhclient-* files to dhclient.conf...')
    other_dhclient_files = `ls -1 /etc/dhcp/*conf|grep -v dhclient.conf`.split("\n")
    other_dhclient_files.each do |file|
       Chef::Log.info("linking #{file}")
       `rm -f #{file}`
      `ln -sf /etc/dhcp/dhclient.conf #{file}`
    end

    dhclient_kill_service='killdhclient'
    dhclient_kill_script = "/etc/init.d/#{dhclient_kill_service}"

    # attribute dhclient will be false if the compute is to use the more static approach to ip address. we are to eliminate dhclient process
    attrs = node[:workorder][:rfcCi][:ciAttributes]
    if attrs[:dhclient] == 'false' && node.platform != 'ubuntu'
        # prepend to the /etc/resolv.conf file as well
        Chef::Log.info('adjusting resolv.conf because dhclient not desired')
        Chef::Log.info("resolv search #{customer_domains_dot_terminated}")
        `cp -f /etc/resolv.conf /etc/resolv.conf.orig ; true`
        ## note- further nameserver entries will already be in the file at this point
        `echo '; gen by remote.rb' > /etc/resolv.conf.mod ; true`
        `echo 'search #{customer_domains_dot_terminated}' >> /etc/resolv.conf.mod ; true`
        # skip caching dns for containers
        `echo 'nameserver 127.0.0.1' >> /etc/resolv.conf.mod ; true` unless ['docker'].index(provider)
        `echo '#_' >> /etc/resolv.conf.mod ; true`
        `grep nameserver /etc/resolv.conf.orig | grep -v 127.0.0.1 >> /etc/resolv.conf.mod; true`
        `cp -f /etc/resolv.conf.mod /etc/resolv.conf.mod2 ; true`
        `cat /etc/resolv.conf.mod > /etc/resolv.conf ; true`

        # leave behind a script that will stop dhclient for after reboots
        if !File.exists?("#{dhclient_kill_script}")
           Chef::Log.info("writing executable script #{dhclient_kill_script} to kill dhclient because dhclient not desired")
           `echo '#!/bin/sh' > #{dhclient_kill_script} ; true`

            #`echo '# #{dhclient_kill_script} kills dhclient' >> #{dhclient_kill_script} ; true`
           #start=run level 23  start-priority=17
           `echo '# chkconfig:   23 17 17' >> #{dhclient_kill_script} ; true`
           `echo '# description: kills the dhclient' >> #{dhclient_kill_script} ; true`
           `echo '### BEGIN INIT INFO' >> #{dhclient_kill_script} ; true`
           `echo '# Provides: dhclient kill' >> #{dhclient_kill_script} ; true`
           `echo '# Required-Start: $network' >> #{dhclient_kill_script} ; true`
           `echo '### END INIT INFO' >> #{dhclient_kill_script} ; true`
           `echo '##generated by remote.rb' >> #{dhclient_kill_script} ; true`

           `echo 'start() {' >> #{dhclient_kill_script} ; true`
           `echo 'sleep 10' >> #{dhclient_kill_script} ; true`
           `echo 'ps -ef|grep -v grep|grep dhclient > /var/log/dhclient_kill.log' >> #{dhclient_kill_script} ; true`
           `echo 'pkill -f dhclient' >> #{dhclient_kill_script} ; true`
           `echo 'RETVAL=$?' >> #{dhclient_kill_script} ; true`
           `echo 'echo $RETVAL >> /var/log/dhclient_kill.log' >> #{dhclient_kill_script} ; true`
           `echo '}' >> #{dhclient_kill_script} ; true`
           `echo 'stop() {' >> #{dhclient_kill_script} ; true`
           `echo ' :' >> #{dhclient_kill_script} ; true`
           `echo '}' >> #{dhclient_kill_script} ; true`
           `echo '# See how we were called.' >> #{dhclient_kill_script} ; true`
           `echo 'case "$1" in' >> #{dhclient_kill_script} ; true`
           `echo ' start)' >> #{dhclient_kill_script} ; true`
           `echo '   start' >> #{dhclient_kill_script} ; true`
           `echo '   ;;' >> #{dhclient_kill_script} ; true`
           `echo ' stop)' >> #{dhclient_kill_script} ; true`
           `echo '   stop' >> #{dhclient_kill_script} ; true`
           `echo '   ;;' >> #{dhclient_kill_script} ; true`
           `echo ' *)' >> #{dhclient_kill_script} ; true`
           `echo '   echo "Usage: $0 {start|stop}"' >> #{dhclient_kill_script} ; true`
           `echo '   exit 2' >> #{dhclient_kill_script} ; true`
           `echo 'esac' >> #{dhclient_kill_script} ; true`
           `chmod +x #{dhclient_kill_script}`
        end
        `chkconfig --add #{dhclient_kill_service}`
    elsif node.platform != 'ubuntu'
        # remove the script that stops dhclient. it might not be there - it is ok
        `chkconfig --list #{dhclient_kill_service}`
        if $?.to_i == 0
            Chef::Log.info("removing script that kills dhclient - #{dhclient_kill_script} - dhclient is desired if we boot")
            `chkconfig --del #{dhclient_kill_service}`
        else
            Chef::Log.info('no need to remove script that kills dhclient - it was not here')
        end
    end

    dhclient_cmdline = '/sbin/dhclient'
  
    # try to use options that its running with
    dhclient_ps = `ps auxwww|grep -v grep|grep dhclient`
    if dhclient_ps.to_s =~ /.*:\d{2} (.*dhclient.*)/
        dhclient_cmdline = $1
    end    
    
    # always kill
   `pkill -f dhclient`

    # prevent dhcp from overwriting /etc/resolv.conf
    if node.platform == 'ubuntu'
      `resolvconf --disable-updates`
    end

    # but restart (and leave running) if dhclient is choice selected. and leave it down otherwise
    if attrs[:dhclient] == 'true'
      Chef::Log.info("starting: #{dhclient_cmdline}")
      output = `#{dhclient_cmdline}`
      Chef::Log.info("returned: #{output} exitstatus: #{$?.exitstatus}")

    else
       Chef::Log.info('will not start dhclient because dhclient not desired')
    end

  end
end


service 'Starting bind service' do
  case node['platform']
    when 'redhat', 'centos', 'fedora', 'suse'
      service_name 'named'
    when 'ubuntu', 'debian'
      service_name 'bind9'
    else
      service_name 'named'
  end
  supports :restart => true
  action [:enable, :restart]
end


# DHCLIENT

# Baremetal compute should have the interface name detected dynamically.
case node.platform

  when 'fedora', 'redhat', 'centos'
    if !compute_baremetal.nil? && compute_baremetal =~/true/
      Chef::Log.info('This is a baremetal compute. Interface will be detected dynamically.')
      active_interface = `ip route list|grep default |awk '{print $5}'`
      Chef::Log.info("Active interface is #{active_interface}")
      file = "/etc/sysconfig/network-scripts/ifcfg-#{active_interface}"
      `grep PERSISTENT_DHCLIENT #{file}`
      if $?.to_i != 0
        Chef::Log.info('PERSISTENT DHCLIENT setting - network restart')
        `echo -e "\nPERSISTENT_DHCLIENT=1" >> #{file} ; /sbin/service network restart`
      else
        Chef::Log.info('DHCLIENT already configured')
      end
    else
      Chef::Log.info('This is a regular compute. Interface will be eth0')
      file = '/etc/sysconfig/network-scripts/ifcfg-eth0'
      `grep PERSISTENT_DHCLIENT #{file}`
      if $?.to_i != 0
        Chef::Log.info('DHCLIENT setting ifcfg-eth0 - network restart')
        `echo "PERSISTENT_DHCLIENT=1" >> #{file}; hostnamectl set-hostname #{node.vmhostname}; /sbin/service network restart`
      else
        Chef::Log.info('DHCLIENT already configured')
      end
    end

end

ruby_block 'printing hostname fqdn' do
  block do
    fqdn = `hostname -f`
    Chef::Log.info("Executing 'hostname -f' : #{fqdn}")
  end
end
