actions :create, :update, :run, :stop, :delete

attribute :task_name, kind_of: String, name_attribute: true
attribute :description, kind_of: String, default: ''
attribute :path, kind_of: String, required: true
attribute :arguments, kind_of: String, default: ''
attribute :working_directory, kind_of: String, default: ''
attribute :user_id, kind_of: String, required: true
attribute :password, kind_of: String
attribute :type, equal_to: ['daily', 'once', 'weekly'], default: 'once'
attribute :execution_time_limit, kind_of: String, default: 'P3D'
attribute :start_day, kind_of: String,  required: true
attribute :start_time, kind_of: String, required: true
attribute :days_interval, kind_of: Integer, default: 1
attribute :days_of_week, kind_of: String, default: 'Sunday'
attribute :weeks_interval, kind_of: Integer, default: 1

attr_accessor :exists, :status
