#
# Cookbook Name:: compute
# Recipe:: base
#
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

node.set["use_initial_user"] = true

include_recipe "shared::set_provider_new"
include_recipe "compute::ssh_port_wait"
include_recipe "compute::ssh_cmd_for_remote"

ruby_block 'wait for ssh' do
  block do
    node[:ostype] =~ /windows/ ? (wait_time = 20) : (wait_time = 4)

    # Wait until we can get a response from VM
    start_time = Time.now.to_i
    i = 1
    ssh_failed = true
    ssh_cmd = node[:ssh_interactive_cmd].gsub('IP',node[:ip])
    ssh_cmd = "#{ssh_cmd}hostname > /dev/null".gsub(
      'StrictHostKeyChecking=no','StrictHostKeyChecking=no -o ConnectTimeout=5'
    )
    Chef::Log.info("Started waiting for ssh response from #{node[:ip]}")
    Chef::Log.info("SSH command is: #{ssh_cmd}")

    # Try connecting for 300 seconds
    while Time.now.to_i - start_time < 300 do
      Chef::Log.info( "Attempt:#{i} to get a valid ssh response from #{node[:ip]} ...")
      result = system(ssh_cmd)

      if result
        ssh_failed = false
        Chef::Log.info( "Received a valid response from #{node[:ip]}! Moving on to a next step...")
        break
      end

      Chef::Log.info( "Did not receive a valid response from #{node[:ip]}. Retrying...")
      sleep wait_time
      i += 1
    end #while

    if ssh_failed
      puts "***FATAL: SSH - we did not receive a valid response in 300 seconds"
      raise("SSH - we did not receive a valid response in 300 seconds")
    end
  end
end if node[:workorder][:rfcCi][:rfcAction] !~ /update/

ruby_block 'install base' do
  block do

    ssh_interactive_cmd = node[:ssh_interactive_cmd].gsub('IP',node[:ip])
    rsync_cmd = node[:rsync_cmd].gsub('IP',node[:ip])

    fast_image = (node.has_key?('fast_image') && node['fast_image'])
    if fast_image
      Chef::Log.info("Detected fast image");
    else
      Chef::Log.info("No fast image detected");
    end

    Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
    shell_timeout = 36000

    # install os package repos - repo_map keyed by os
    os_type = node[:ostype]
    cloud_name = node[:workorder][:cloud][:ciName]
    services = node['workorder']['services']
    compute_attr = services['compute'][cloud_name]['ciAttributes']

    unless fast_image
      repo_cmds = []
      if compute_attr.has_key?('repo_map') &&
         compute_attr[:repo_map].include?(os_type)

        repo_map = JSON.parse(compute_attr[:repo_map])
        repo_cmds = [repo_map[os_type]]
        Chef::Log.debug("repo_cmds: #{repo_cmds.inspect}")
      else
        Chef::Log.info("no key in repo_map for os: " + os_type);
      end

      # add repo_list from os
      if node.has_key?("repo_list") && !node[:repo_list].nil? && node[:repo_list].include?('[')
        Chef::Log.info("adding compute-level repo_list: #{node[:repo_list]}")
        repo_cmds += JSON.parse(node[:repo_list])
      end

      if repo_cmds.size > 0
        # todo: set proxy env vars - current use case not required
        cmd = "#{ssh_interactive_cmd}\"#{repo_cmds.join('; ')}\""
        Chef::Log.info("running setup repos: #{cmd}")
        result = `#{cmd}`
        if result.to_i != 0
          puts '***FATAL: executing repo commands from the compute cloud '/
               'service, repo_map attr and compute repo_list attr'
          Chef::Log.error("cmd: #{cmd} returned: #{result}")
        end
      end
    end

    Chef::Log.info('Installing base sw for oneops ...')
    # Determine command prefix (sudo/powershell)
    cmd_prefix = ''
    if os_type =~ /windows/
      cmd_prefix = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File '
    elsif !node[:ssh_cmd].include?('root@')
      cmd_prefix = 'sudo '
    end

    # Determine install_base file
    base_file = "install_base.#{os_type =~ /windows/ ? 'ps1' : 'sh'}"
    base_file = "install_fastimage_base.sh" if fast_image
    dest_dir  = os_type =~ /windows/ ? '' : '~/'

    # Determine command arguments
    args = ''
    unless fast_image
      env_vars = JSON.parse(compute_attr['env_vars'])
      Chef::Log.info("env_vars: #{env_vars.inspect}")

      if os_type =~ /windows/
        env_vars.each_pair do |k,v|
          args += case k
                  when 'apiproxy' then "-proxy '#{v}' "
                  when 'rubygems' then "-gemRepo '#{v}' "
                  else ''
                  end
        end

        if services.has_key?('mirror') &&
           services['mirror'][cloud_name]['ciAttributes'].has_key?('mirrors')

           mirror_vars = JSON.parse( 
             services['mirror'][cloud_name]['ciAttributes']['mirrors']
           )
           mirror_vars.each_pair do |k,v|
             args += case k
                     when 'chocopkg' then "-chocoPkg '#{v}' "
                     when 'chocorepo' then "-chocoRepo '#{v}' "
                     else ''
                     end
           end
        else
          Chef::Log.info('Compute does not have mirror service included')
        end
      else
        env_vars.each_pair{ |k,v| args += "#{k}:#{v} " }
      end # if os_type =~ /windows/
    end # unless fast_image

    # copy install file to VM
    base_dir = File.join(
      File.expand_path('../../', __FILE__), '/files/default/'
    )
    source_file = File.join(base_dir, base_file)
    Chef::Log.info("Copying #{source_file} ...")
    cmd = rsync_cmd.gsub("SOURCE",source_file).gsub("DEST","~/")
    result = shell_out(cmd, :timeout => shell_timeout)
    Chef::Log.debug("#{cmd} returned: #{result.stdout}")
    result.error!

    # Execute install base file on the VM
    cmd = "#{ssh_interactive_cmd} \"#{cmd_prefix}#{dest_dir}#{base_file} #{args}\""
    Chef::Log.info("Executing Command: #{cmd}")
    result = shell_out(cmd, :timeout => shell_timeout)
    Chef::Log.debug("#{cmd} returned: #{result.stdout}")
    result.error!

    # Create sudo file for windows
    if os_type =~ /windows/
      sudo_file = File.join(base_dir, 'sudo')
      Chef::Log.info("Copying #{sudo_file} ...")
      cmd = rsync_cmd.gsub("SOURCE",sudo_file).gsub("DEST","/usr/bin/")
      result = shell_out(cmd, :timeout => shell_timeout)
      Chef::Log.debug("#{cmd} returned: #{result.stdout}")
      result.error!

      cmd = "#{ssh_interactive_cmd}chmod +x /usr/bin/sudo"
      Chef::Log.info("Executing Command: #{cmd}")
      result = shell_out(cmd, :timeout => shell_timeout)
      Chef::Log.debug("#{cmd} returned: #{result.stdout}")
      result.error!
    end

    cmd = node[:ssh_cmd].gsub("IP",node[:ip]) + "\"grep processor /proc/cpuinfo | wc -l\""
    result = shell_out(cmd, :timeout => shell_timeout)
    cores = result.stdout.gsub("\n","")
    puts "***RESULT:cores=#{cores}"

    cmd = node[:ssh_cmd].gsub("IP",node[:ip]) + "\"free | head -2 | tail -1 | awk '{ print \\$2/1024 }'\""
    puts cmd
    result = shell_out(cmd, :timeout => shell_timeout)
    ram = result.stdout.gsub("\n","")
    puts "***RESULT:ram=#{ram}"
  end
end
