# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Cookbook Name:: os
# Recipe:: add
#

cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name]
provider = compute_service[:ciClassName].gsub("cloud.service.","").downcase
Chef::Log.info("provider: #{provider} ..")
node.set['cloud_provider'] = provider

ostype = node[:workorder][:rfcCi][:ciAttributes][:ostype]
Chef::Log.info("OS type: #{ostype} ...")

#remove two out of three json gem so that it will not create conflit for azure gems
if (ostype =~ /ubuntu-16.04/)
  Chef::Log.info("Resolving json conflict")
  `sudo gem uninstall json -v 2.0.2`
  `sudo gem uninstall json -v 1.8.6`
end


#Symlinks for windows
if ostype =~ /windows/
  ["etc","opt","var"].each do |dir_name|
    link "C:/#{dir_name}" do
      to "C:/cygwin64/#{dir_name}"
      only_if{::File.directory?("C:/cygwin64/#{dir_name}")}
    end
  end
end

#Perform common recipes (both linux and windows)
include_recipe "os::time"
include_recipe "os::perf_forwarder" 
include_recipe "os::add-conf-files"

platform_name = node.workorder.box.ciName
if(platform_name.size > 32)
  platform_name = platform_name.slice(0,32) #truncate to 32 chars
  Chef::Log.info("Truncated platform name to 32 chars : #{platform_name}")
end
vmhostname = platform_name+'-'+node["workorder"]["cloud"]["ciId"].to_s+'-'+node["workorder"]["rfcCi"]["ciName"].split('-').last.to_i.to_s+'-'+ node["workorder"]["rfcCi"]["ciId"].to_s
if ostype =~ /windows/ #limiting hostname to 15 characters for Windows
  ciId_s = node["workorder"]["rfcCi"]["ciId"].to_s
  id_length = ciId_s.to_s.length
  vmhostname = platform_name[0..(15-id_length-2)] +'-'+ ciId_s
end
node.set[:vmhostname] = vmhostname.downcase
node.set[:full_hostname] = node["vmhostname"]+'.'+node["customer_domain"].downcase

if provider =~ /azure/ && compute_service[:ciAttributes][:express_route_enabled] == 'false'
  Chef::Log.info("Setting DNS label on public_ip")
  puts "***RESULT:hostname=#{node.full_hostname}"
else
  puts "***RESULT:hostname=#{node.vmhostname}"
end

uname_output=`uname -srvmpo`.to_s.gsub("\n","")
puts "***RESULT:osname=#{node.platform}-#{node.platform_version} #{uname_output}"

#Perform windows-specific recipes and exit
if ostype =~ /windows/
  `sed -i 's/.*StrictModes .*/StrictModes no/' /etc/sshd_config`

  features = JSON.parse(node[:workorder][:rfcCi][:ciAttributes][:features])
  Chef::Log.info("Features to install: #{features.inspect}")

  features.each do |feature|
    powershell_script "Install-#{feature.split(' ').first}" do
      code "Install-WindowsFeature -Name #{feature}"
      only_if "(Get-WindowsFeature #{feature.split(' ').first}).InstallState -eq 'Available'"
    end
  end

  include_recipe "os::logrotate_windows"
  include_recipe "os::network_windows"

  #Determine if additional restart needed
  features.each do |feature|
    ruby_block "declare-restart-#{feature.split(' ').first}" do
      block do
        puts "***REBOOT_FLAG***"
      end
      guard_interpreter :powershell_script
      only_if "(Get-WindowsFeature #{feature.split(' ').first}).InstallState -eq 'InstallPending'"
      notifies :reboot_now, 'reboot[perform-restart]', :immediately
    end
  end

  return true
end

#Perform non-windows recipes
# common plugins dir that components put their check scripts
execute "mkdir -p /opt/nagios/libexec"

include_recipe "os::packages"
include_recipe "os::network"
include_recipe "os::proxy"
include_recipe "os::kernel" unless provider == "docker"
include_recipe "os::security" unless provider == "docker"


template "/etc/logrotate.d/oneops" do
  cookbook "os"
  source "logrotate.erb"
  owner "root"
  group "root"
  mode 0644
end

ruby_block 'setup share' do
  only_if { provider == "virtualbox" }
  block do

    rfcCi = node[:workorder][:rfcCi]
    nsPathParts = rfcCi[:nsPath].split("/")
    server_name = rfcCi[:ciName]+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi[:ciId].to_s

    cmd = "grep #{server_name} /etc/fstab"
    Chef::Log.info("cmd: #{cmd}")
    result = `#{cmd}`

    if result.to_i != 0 || result.to_s.empty?
      cmd = "echo \"#{server_name} /mnt vboxsf rw 0 0\" >> /etc/fstab"
      Chef::Log.info("cmd: #{cmd}")
      `#{cmd}`
      `mount -a`
    end

  end
end

# install LDAP
attrs = node[:workorder][:rfcCi][:ciAttributes]
services = node[:workorder][:services]

if !services.nil? &&  services.has_key?(:ldap)
  Chef::Log.info("Enable ldap service")
  include_recipe "os::add_ldap"
else
  Chef::Log.info("Disabling ldap service")
  include_recipe "os::delete_ldap"
end

# sshd
execute "cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup"

template "/etc/ssh/sshd_config" do
  cookbook "os"
  source "sshd_config.erb"
  owner "root"
  group "root"
  mode 0644
  only_if { node.platform == "redhat" || node.platform == "centos" }
end

ruby_block 'ssh config' do
  block do

    if node.platform == "redhat" || node.platform == "centos"
      result = `service sshd restart`.to_i

      if result != 0
        `cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config ; service sshd restart`
        exit_with_error "new ssh config is bad. fix the sshd_config attribute. reverting and exiting."
      end

    end

  end
end

Chef::Log.info("Updating security and bash.")

package "bash" do
  action :upgrade
end

case node.platform
when "redhat","centos","fedora"
  if node.platform_version.to_i < 7
    package "yum-security"
    execute "yum -y update --security"
  end
end

include_recipe "os::postfix" unless provider == "docker"
