windows_service = node['windowsservice']

if windows_service.user_account == 'SpecificUser'
  if !windows_service.username.include?('\\')
    user_name = ".\\#{windows_service.username}"
  else
    user_name = windows_service.username
  end
  node.set['workorder']['rfcCi']['ciAttributes']['user_right'] = "SeServiceLogonRight"
  include_recipe 'windows-utils::assign_user_rights'
else
  user_name = windows_service.user_account
end

version = node['workorder']['rfcCi']['ciAttributes']['package_version']
package_name = windows_service.package_name
windows_service_path = "#{windows_service.physical_path}\\#{package_name}\\#{version}\\#{windows_service.path}"

if windows_service.service_display_name.nil? || windows_service.service_display_name.empty?
  win_service_display_name = windows_service.service_name
else
  win_service_display_name = windows_service.service_display_name
end

service_dependencies = ( windows_service.dependencies.nil? ||  windows_service.dependencies.empty? ) ? nil : JSON.parse(windows_service.dependencies)
windowsservice windows_service.service_name do
  action [:create, :update]
  service_name windows_service.service_name
  service_display_name win_service_display_name
  path windows_service_path
  startup_type windows_service.startup_type
  dependencies service_dependencies
  username user_name
  password windows_service.password
end

include_recipe 'windowsservice::restart_service'
