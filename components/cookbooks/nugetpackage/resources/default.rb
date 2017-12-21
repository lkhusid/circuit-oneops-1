actions :install, :update, :delete

attribute :repository_url, kind_of: String
attribute :physical_path, kind_of: String, required: true
attribute :name, kind_of: String, name_attribute: true
attribute :version, kind_of: String
attribute :deployment_directory, kind_of: String, default: 'c:\platform_deployment'
