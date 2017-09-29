windows_service = node['windowsservice']
service_arguments = ( windows_service.arguments.nil? ||  windows_service.arguments.empty? ) ? [] : JSON.parse(windows_service.arguments)

windowsservice windows_service.service_name do
  action :start
  arguments         service_arguments
  wait_for_status   windows_service.wait_for_status
end
