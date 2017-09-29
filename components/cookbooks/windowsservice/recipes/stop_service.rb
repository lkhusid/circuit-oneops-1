windows_service = node['windowsservice']

windowsservice windows_service.service_name do
  action :stop
end
