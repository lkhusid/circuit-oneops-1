actions :create, :update, :delete
default_action :create

attribute :name, kind_of: String, name_attribute: true

attribute :site_name, kind_of: String, default: '', required: true
attribute :virtual_directory_path, kind_of: String, default: '/'
attribute :virtual_directory_physical_path, kind_of: String, default: 'c:/apps'
attribute :application_path, kind_of: String, required: true
attribute :application_pool, kind_of: String, default: 'defaultapppool'
