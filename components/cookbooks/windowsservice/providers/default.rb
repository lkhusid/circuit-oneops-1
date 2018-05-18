WINDOWS_SERVICE_PROPERTIES = {
  'service_name'          =>  'service_name',
  'service_display_name'  =>  'display_name',
  'startup_type'          =>  'start_type',
  'path'                  =>  'binary_path_name',
  'username'              =>  'service_start_name',
  'password'              =>  'password',
  'dependencies'          =>  'dependencies'
}

RECOVERY_ATTRIBUTES = {
  'failure'               => 'failure_actions',
  'reset_fail_counter'    => 'failure_reset_period',
  'restart_service_after' => 'failure_delay',
  'command'               => 'failure_command'
}

SERVICE_STARTUP_TYPE = {
  'auto start'   => 2,
  'demand start' => 3,
  'disabled'     => 4
}

SERVICE_RECOVERY_TYPE = {
  'TakeNoAction' => 0,
  'RestartService' => 1,
  'RestartComputer'=> 2,
  'RunCommand' => 3
}

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @service_windows = OO::WindowsService.new

  @current_resource.service_name(new_resource.service_name)

  if @service_windows.service_exists?(@current_resource.service_name)
    service_attributes = @service_windows.get_windows_service_attribute(@current_resource.service_name)
    @current_resource.exists = true
    @current_resource.status = @service_windows.service_status(@current_resource.service_name)
    WINDOWS_SERVICE_PROPERTIES.each_key do |property_name|
      @current_resource.send(property_name, service_attributes[property_name])
    end
  end
end

action :create do
  if @service_windows.service_exists?(new_resource.service_name)
    Chef::Log.info "The service #{new_resource.service_name} already exist."
  else
    @service_windows.create_service(get_windows_service_attributes)
    Chef::Log.info "Successfully installed the service #{new_resource.service_name}."
    new_resource.updated_by_last_action(true)
  end
end

action :update do
  if @current_resource.exists
    windows_service_attributes = {}
    windows_service_attributes['service_name'] = new_resource.service_name
    WINDOWS_SERVICE_PROPERTIES.each_pair do |property_name, value_property_name|
      windows_service_attributes[value_property_name] = new_resource.send(property_name) if resource_needs_change(property_name) && property_name != "dependencies"
    end
    windows_service_attributes['start_type'] = SERVICE_STARTUP_TYPE[windows_service_attributes['start_type']] unless windows_service_attributes['start_type'].nil?
    @service_windows.update_service(windows_service_attributes)
    update_dependencies
    windows_service_attributes = update_service_recovery(windows_service_attributes)
    Chef::Log.info "Windows Service Attributes - #{windows_service_attributes}"
    @service_windows.update_service(windows_service_attributes)
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{new_resource.service_name} does not exist. Nothing to do."
  end
end

action :start do
  if @current_resource.exists
    if @current_resource.status != 'running' && @current_resource.startup_type != 'disabled'
      Chef::Log.info "Inside Start #{@current_resource.service_name} #{@current_resource.status}"
      @service_windows.start_service(new_resource.service_name, new_resource.arguments)
      sleep new_resource.wait_for_status.to_i
      status = @service_windows.service_status(@current_resource.service_name)
      Chef::Log.warn "The service could not be started. The service is : #{status}" if status != 'running'
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource.service_name} is already runnings. Nothing to do."
    end
  else
    Chef::Log.info "#{new_resource.service_name} does not exist."
  end
end

action :stop do
  if @current_resource.exists
    if @current_resource.status == 'running'
      @service_windows.stop_service(new_resource.service_name)
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "#{new_resource.service_name} is not running. Nothing to do."
    end
  else
    Chef::Log.info "#{new_resource.service_name} does not exist."
  end
end

def get_windows_service_attributes
  attributes = {}
  WINDOWS_SERVICE_PROPERTIES.each_pair do |property_name, value_property_name|
    attributes[value_property_name] = new_resource.send(property_name)
  end
  RECOVERY_ATTRIBUTES.each_pair do |property_name, value_property_name|
    attributes[value_property_name] = new_resource.send(property_name)
  end

  arr = attributes['failure_actions']
  attributes['start_type'] = SERVICE_STARTUP_TYPE[attributes['start_type']]
  attributes["failure_delay"] = attributes["failure_delay"].to_i
  attributes["failure_reset_period"] = attributes["failure_reset_period"].to_i
  attributes['failure_actions'] = arr.map { |element| SERVICE_RECOVERY_TYPE[element] } unless arr.nil?

  attributes
end

def update_service_recovery(attributes)
  arr = new_resource.failure
  attributes["failure_command"]= new_resource.command
  attributes["failure_delay"] = new_resource.restart_service_after.to_i
  attributes["failure_reset_period"] = new_resource.reset_fail_counter.to_i
  attributes['failure_actions'] = arr.map { |element| SERVICE_RECOVERY_TYPE[element] } unless arr.nil?

  attributes
end

def update_dependencies
  dependencies = (new_resource.dependencies.nil? || new_resource.dependencies.empty?) ?  "/" : new_resource.dependencies.join('/')

  if new_resource.dependencies != @current_resource.dependencies
    cmd = Mixlib::ShellOut.new("sc config #{new_resource.service_name} depend= #{dependencies}")
    cmd.run_command
  end
end

def resource_needs_change property_name
  property_name == 'password' || property_name == 'username' || new_resource.send(property_name) != current_resource.send(property_name)
end
