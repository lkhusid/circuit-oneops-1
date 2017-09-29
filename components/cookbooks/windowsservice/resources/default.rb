actions :create, :update, :start, :stop

attribute :service_name, kind_of: String, name_attribute: true
attribute :service_display_name, kind_of: String, default: ''
attribute :path, kind_of: String
attribute :startup_type, equal_to: ['auto start', 'demand start', 'disabled'], default: 'auto start'
attribute :arguments, kind_of: Array, default: []
attribute :dependencies, kind_of: Array, default: nil
attribute :username, kind_of: String
attribute :password, kind_of: String
attribute :wait_for_status, kind_of: String

attr_accessor :exists, :status
