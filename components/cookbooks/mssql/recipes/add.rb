#
# Cookbook Name:: mssql
# Recipe:: add
#
require 'uri'

#Grab URL from the mirror service
version_full = node['mssql']['version']
cloud_name = node[:workorder][:cloud][:ciName]
services = node[:workorder][:services]
ps_script = "#{Chef::Config[:file_cache_path]}/cookbooks/os/files/windows/Run-Script.ps1"

Chef::Log.info( "Installing MS SQL Server edition: #{version_full}")

if services.has_key?(:mirror)
  initial_url = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])[version_full]
else
  msg = 'Mirror service required for MS SQL!!!'
  puts"***FAULT:FATAL=#{msg}"
  e=Exception.new("#{msg}")
  e.set_backtrace('')
  raise e
end

if initial_url.nil? || initial_url.size == 0
  msg = "Could not find url for #{version_full} in mirror service!!"
  puts"***FAULT:FATAL=#{msg}"
  e=Exception.new("#{msg}")
  e.set_backtrace('')
  raise e
end

Chef::Log.info( "url - #{initial_url}")

uri = URI.parse(initial_url)
ext = File.extname(uri.to_s)
config_file_path = "#{Chef::Config[:file_cache_path]}/ConfigurationFile.ini"
sql_sys_admin_list = if node['sql_server']['sysadmins'].is_a? Array
                       node['sql_server']['sysadmins'].map { |account| %("#{account}") }.join(' ') # surround each in quotes, space delimit list
                     else
                       %("#{node['sql_server']['sysadmins']}") # surround in quotes
                     end


#If URL is for ISO or zip => we need to download and unzip or mount first
if (ext = '.zip' || ext = '.iso')

  temp_drive = 'C'

  #use temp_drive (OO_LOCAL variable) if it has enough space
  if node[:workorder][:payLoad].has_key?(:OO_LOCAL_VARS)
    local_vars = node.workorder.payLoad.OO_LOCAL_VARS
    local_vars_index = local_vars.index { |resource| resource[:ciName] == 'temp_drive' }

    if !local_vars_index.nil?
      var_value = local_vars[local_vars_index][:ciAttributes][:value]
      cmd_out = `fsutil volume diskfree #{var_value}:`
      free_space = cmd_out[/\d+/].to_i
      Chef::Log.info( "Space available on #{var_value}: #{free_space} bytes")
      if free_space >= 10000000000
        temp_drive = var_value
      end
    end
  end

  temp_location = "#{temp_drive}:/tmp/mssql"

  output_file = File.join(temp_location, File.basename(uri.path))
  Chef::Log.info( "Output file: #{output_file}")

  directory temp_location do
    recursive true
  end

  powershell_script 'Download SQL Server software' do
    code <<-EOH
    $url = "#{initial_url}"
    $output_file = "#{output_file}"

    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $output_file)
    EOH
    not_if "Test-Path '#{output_file}'"
  end

  powershell_script 'Extract from zipfile' do
    code <<-EOH
    $ErrorActionPreference = "Stop"
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory("#{output_file}", "#{temp_location}/distr")
    EOH
    not_if "Test-Path '#{temp_location}/distr'"
    only_if {ext='.zip'}
  end

  #Find full path to setup.exe and its checksum
  ruby_block 'Find setup.exe' do
    block do
      ::Chef::Recipe.send(:include, Chef::Mixin::PowershellOut)
      ps_code = "$dir = '#{temp_location}/distr'
      $a = Get-ChildItem -Path $dir -Filter setup.exe
      if (!$a) {
        $b = Get-ChildItem -Path $dir | ?{ $_.PSIsContainer }
        $a = Get-ChildItem $b.FullName -Filter setup.exe }
      $a.FullName + ','  + (Get-FileHash $a.FullName).Hash"

      cmd = powershell_out!(ps_code)
      Chef::Log.info( "Powershell returned: #{cmd.stdout}")

      new_url = cmd.stdout.split(",").first
      new_checksum = cmd.stdout.split(",").last.downcase

      node.override['sql_server']['server']['url'] = new_url
      node.default['mssql']['setup'] = new_url
      node.override['sql_server']['server']['checksum'] = new_checksum

      Chef::Log.info( "Latest URL - #{node['sql_server']['server']['url']}")
      Chef::Log.info( "Latest checksum - #{node['sql_server']['server']['checksum']}")

    end #block do
  end #ruby_block 'Find setup.exe' do

end #if (ext = '.zip' || ext = '.iso')

#Adjust the PS resource to take runtime values for parameters
ruby_block 'Adjust PS resource' do
  block do

    arglist = "-sql_version_num #{node['sql_server']['version_num']} -setup_file '#{node['sql_server']['server']['url']}' -arg_list '/q /ConfigurationFile=#{config_file_path}'"
    r = run_context.resource_collection.find(:elevated_script => 'Install-Mssql-Features')
    r.arglist(arglist)
  end #block do
end #ruby_block 'Adjust PS resource' do


features_install = nil
features_uninstall = nil
if !(::Win32::Service.exists?(node['sql_server']['instance_name']))
  Chef::Log.info( "Service does not exist - installing")
  features_install = node['mssql']['feature_list']
else
  if node[:workorder][:rfcCi][:ciBaseAttributes].has_key?('feature_list')
    Chef::Log.info( "Service exists and feature_list changed - updating")
    arr_features_base = node[:workorder][:rfcCi][:ciBaseAttributes]['feature_list'].split(',')
    arr_features_new = node[:workorder][:rfcCi][:ciAttributes]['feature_list'].split(',')

    features_install = (arr_features_new - arr_features_base).join(',')
    features_uninstall = (arr_features_base - arr_features_new).join(',')
  end
end #if !(::Win32::Service.exists?(node['sql_server']['instance_name'])

Chef::Log.info( "Features to install: #{features_install}")
Chef::Log.info( "Features to uninstall: #{features_uninstall}")

#Install features
template config_file_path do
  cookbook 'mssql'
  source 'ConfigurationFile.ini.erb'
  variables(
    sqlSysAdminList: sql_sys_admin_list,
    action: 'Install',
    feature_list: features_install
  )
  not_if {features_install.nil? || features_install.size == 0}
end


ps_script = "#{Chef::Config[:file_cache_path]}\\cookbooks\\mssql\\files\\windows\\Install-Mssql.ps1"
elevated_script 'Install-Mssql-Features' do
  script ps_script
  timeout 1800
  arglist ''
  not_if {features_install.nil? || features_install.size == 0}
end

#Uninstall features
setup_file = "#{node['sql_server']['install_dir']}\\#{node['sql_server']['version_num']}\\Setup Bootstrap\\SQLServer#{node['sql_server']['version']}\\setup.exe"
arglist = "-sql_version_num #{node['sql_server']['version_num']} -setup_file '#{setup_file}' "
arglist += "-arg_list '/Action=Uninstall /Features=#{features_uninstall} /Instancename=#{node['sql_server']['instance_name']} /QUIET=\"True\"'"

elevated_script 'Uninstall-Mssql-Features' do
  script ps_script
  timeout 1800
  arglist arglist
  not_if {features_uninstall.nil? || features_uninstall.size == 0}
end


#TO-DO Add password options to setup command string

#declare a resource to run setup command

include_recipe 'mssql::configure'
include_recipe 'mssql::monitoring'
include_recipe 'mssql::sysadmins'
