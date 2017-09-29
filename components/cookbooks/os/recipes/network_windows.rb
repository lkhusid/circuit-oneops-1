#Disable auto DNS registration
lan_name = 'Ethernet'
powershell_script 'Disable-DNSRegistration' do
  code "((Get-WMIObject Win32_NetworkAdapter -filter \"NetConnectionID = '#{lan_name}'\").Getrelated('Win32_NetworkAdapterConfiguration')).SetDynamicDNSRegistration($false,$false)"
  only_if "((Get-WMIObject Win32_NetworkAdapter -filter \"NetConnectionID = '#{lan_name}'\").Getrelated('Win32_NetworkAdapterConfiguration')).FullDNSRegistrationEnabled"
end

pw_file = '/etc/passwd'
execute "mkpasswd -l -u oneops > #{pw_file}" do
  guard_interpreter :powershell_script
  not_if "(Test-Path #{pw_file}) -And (Get-Content #{pw_file}) -Like '*oneops:*/home/oneops*'"
end

#1. Rename VM and restart
powershell_script 'Rename-Computer' do
  code "Rename-Computer -NewName '#{node[:vmhostname]}' -Force -ErrorAction Stop"
  only_if "$env:computername -ne '#{node[:vmhostname]}'"
end

#2. join windows domain if service exists and restart
if node[:workorder][:services].has_key?('windows-domain')

  cloud_name = node[:workorder][:cloud][:ciName]
  domain = node[:workorder][:services]['windows-domain'][cloud_name][:ciAttributes]
  
  ps_code = "#{Chef::Config[:file_cache_path]}/cookbooks/os/files/windows/Join-Domain.ps1"
  ps_code += " -domain '#{domain[:domain]}' -password '#{domain[:password]}' -username '#{domain[:username]}'"

  powershell_script 'Join-Domain' do
    code ps_code
    sensitive true
    not_if '(gwmi win32_computersystem).partofdomain'
  end

end


#restart
ruby_block 'declare-restart' do
  block do
    puts "***REBOOT_FLAG***"
  end
  action :nothing
  subscribes :run, 'powershell_script[Join-Domain]', :immediately
  subscribes :run, 'powershell_script[Rename-Computer]', :immediately
end

reboot 'perform-restart' do
  action :nothing
  subscribes :reboot_now, 'ruby_block[declare-restart]', :immediately
end
