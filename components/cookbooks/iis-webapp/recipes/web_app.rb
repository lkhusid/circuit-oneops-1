web_application = node['iis-webapp']
web_site_name = node['workorder']['box']['ciName']

package_name = web_application['package_name']
web_application_path = web_application['application_path']
physical_path = web_application['physical_path']
version = web_application['version']
new_application_pool_required = web_application.new_app_pool_required.to_bool
web_application_pool = (new_application_pool_required ? package_name : web_site_name)
identity_type = web_application["identity_type"]


package_version = node['workorder']['rfcCi']['ciAttributes']['package_version']
web_application_physical_path = "#{physical_path}\\#{package_name}\\#{package_version}"
Chef::Log.info "The package_version - info: #{package_version}"
Chef::Log.info "The web application physical path - info: #{web_application_physical_path}"

iis_app_pool package_name do
  action  [:create, :update]
  managed_runtime_version         web_application["runtime_version"]
  process_model_identity_type     identity_type
  recycling_log_event_on_recycle  ["Time", "Requests", "Schedule", "Memory", "IsapiUnhealthy", "OnDemand", "ConfigChange", "PrivateMemory"]
  process_model_user_name         web_application.process_model_user_name if identity_type == 'SpecificUser'
  process_model_password          web_application.process_model_password if identity_type == 'SpecificUser'
  only_if { new_application_pool_required }
end

iis_web_app package_name do
  action                            [:create, :update]
  site_name                         web_site_name
  application_path                  web_application_path
  application_pool                  web_application_pool
  virtual_directory_physical_path   web_application_physical_path
end
