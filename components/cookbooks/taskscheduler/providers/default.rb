CONVERSIONS = {
  "path" => ["actions", "path"],
  "working_directory" => ["actions", "working_directory"],
  "arguments" => ["actions", "arguments"],
  "type" => ["triggers", "type"],
  "start_day" => ["triggers", "start_day"],
  "start_time" => ["triggers", "start_time"],
  "days_interval" => ["triggers", "days_interval"],
  "days_of_week" => ["triggers", "days_of_week"],
  "weeks_interval" => ["triggers", "weeks_interval"],
  "execution_time_limit" => ["settings", "execution_time_limit"],
  "description" => ["general", "description"],
  "user_id" => ["principal", "user_id"]
}

AUTHENTICATION = ["password","user_id"]

TASK_STATUS = {
  1 => 'not scheduled',
  3 => 'ready',
  4 => 'running'
}

def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @task_scheduler = OO::TaskScheduler.new(new_resource.task_name)

  assign_attributes_to_current_resource if @task_scheduler.task_exists?
end

def assign_attributes_to_current_resource
  CONVERSIONS.each do |property_name, (category, attribute)|
    value = @task_scheduler.send(category).send(attribute)
    current_resource.send(property_name, value)
  end
end

def get_task_attributes
  task_attributes = Hash.new({})
  CONVERSIONS.each do |property_name, (category, attribute)|
    task_attributes[category][attribute] = new_resource.send(property_name)
  end

  AUTHENTICATION.each { |property_name| task_attributes['authentication'][property_name] = new_resource.send(property_name) }
  task_attributes
end

def resource_needs_change_for?(property)
  new_value = new_resource.send(property)
  current_value = current_resource.send(property)
  (new_value != current_value)
end

action :create do
  unless @task_scheduler.task_exists?
    @task_scheduler.create_task get_task_attributes
    Chef::Log.info "Created task #{new_resource.task_name}"
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "Task #{new_resource.task_name} already exist"
  end
end

action :update do
  if @task_scheduler.task_exists?
    messages = []
    task_attributes = Hash.new({})

    CONVERSIONS.each do |property_name, (category, attribute)|
      new_value = new_resource.send(property_name)
      current_value = current_resource.send(property_name)
      if resource_needs_change_for?(property_name) || (category == 'triggers' && new_resource.send('type') != current_resource.send('type')) #change
        messages << build_message(property_name: property_name, current_value: current_value, new_value: new_value)
        task_attributes[category][attribute] = new_value
      end
    end

    AUTHENTICATION.each { |property_name| task_attributes['authentication'][property_name] = new_resource.send(property_name)}

    if not messages.empty?
      @task_scheduler.update_task task_attributes
      Chef::Log.info "Updated task #{new_resource.task_name}"
      new_resource.updated_by_last_action(true)
    end
  else
    Chef::Log.info "Task #{new_resource.task_name} does not exist"
  end
end

action :delete do
  if @task_scheduler.task_exists?
    if TASK_STATUS[@task_scheduler.get_task_status] == 'running'
      Chef::Log.info "The task #{new_resource.task_name} is running, stopping it"
      @task_scheduler.stop
    end
    @task_scheduler.delete
    Chef::Log.info "Task #{new_resource.task_name} deleted"
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "Task #{new_resource.task_name} does not exist"
  end
end

action :run do
  if @task_scheduler.task_exists?
    if TASK_STATUS[@task_scheduler.get_task_status] != 'running'
      @task_scheduler.start
      Chef::Log.info "Task #{new_resource.task_name} is running"
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "Task #{new_resource.task_name} is already running, nothing to do"
    end
  else
    Chef::Log.info "Task #{new_resource.task_name} does not exist"
  end
end

action :stop do
  if @task_scheduler.task_exists?
    if TASK_STATUS[@task_scheduler.get_task_status] == 'running'
      @task_scheduler.stop
      Chef::Log.info "Task #{new_resource.task_name} stopped"
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.info "Task #{new_resource.task_name} is not running, nothing to do"
    end
  else
    Chef::Log.info "Task #{new_resource.task_name} does not exist"
  end
end


def build_message(options)
  property_name = options[:property_name]
  current_value = property_name.include?("password") ? "********" : options[:current_value]
  new_value = property_name.include?("password") ? "********" : options[:new_value]

  "#{property_name.gsub('_', ' ')} => from: #{current_value}, to: #{new_value}"
end
