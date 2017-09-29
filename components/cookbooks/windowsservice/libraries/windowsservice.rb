require 'OStruct'
require 'rubygems'
require 'win32/service'
include Win32

module OO
  class WindowsService

    def get_windows_service_attribute(service_name)
      windows_service_attributes = {}
      service = Service.config_info(service_name)

      windows_service_attributes['service_name'] = service_name
      windows_service_attributes['service_display_name'] = service.display_name
      windows_service_attributes['path'] = service.binary_path_name
      windows_service_attributes['startup_type'] = service.start_type
      windows_service_attributes['username'] = service.service_start_name
      windows_service_attributes['dependencies'] = service.dependencies

      windows_service_attributes
    end

    def create_service(service_attributes)
      Service.create(service_attributes)
    end

    def update_service(service_attributes)
      Service.configure(service_attributes)
    end

    def service_exists?(service_name)
      Service.exists?(service_name)
    end

    def service_status(service_name)
      Service.status(service_name)['current_state']
    end

    def start_service(service_name, arguments)
      Service.start(service_name, nil, *arguments)
    end

    def stop_service(service_name)
      Service.stop(service_name)
    end
  end
end
