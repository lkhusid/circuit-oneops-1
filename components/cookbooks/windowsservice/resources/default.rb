actions :create, :update, :start, :stop

attribute :service_name, kind_of: String, name_attribute: true
attribute :service_display_name, kind_of: String, default: ''
attribute :path, kind_of: String
attribute :startup_type, equal_to: ['auto start', 'demand start', 'disabled'], default: 'auto start'
attribute :first_failure, equal_to: ['RestartService', 'RestartComputer', 'RunCommand', 'TakeNoAction'], default: 'TakeNoAction'
attribute :second_failure, equal_to: ['RestartService', 'RestartComputer', 'RunCommand', 'TakeNoAction'], default: 'TakeNoAction'
attribute :subsequent_failure, equal_to: ['RestartService', 'RestartComputer', 'RunCommand', 'TakeNoAction'], default: 'TakeNoAction'
attribute :failure, kind_of: Array, default: ['Take No Action', 'Take No Action', 'Take No Action']
attribute :reset_fail_counter, kind_of: Integer, default: 0
attribute :restart_service_after, kind_of: Integer, default: 0
attribute :command, kind_of: String
attribute :arguments, kind_of: Array, default: []
attribute :dependencies, kind_of: Array, default: nil
attribute :username, kind_of: String
attribute :password, kind_of: String
attribute :wait_for_status, kind_of: String

attr_accessor :exists, :status
