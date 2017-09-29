actions :configure
default_action :configure

attribute :name, kind_of: String, name_attribute: true
attribute :site_name, kind_of: String, required: true
attribute :logFormat, kind_of: String, default: 'W3C', equal_to: ["W3C", "IIS","NCSA"]
attribute :directory, kind_of: String, default: '%SystemDrive%\inetpub\logs\LogFiles'
attribute :enabled, kind_of: [TrueClass, FalseClass], default: true
attribute :period, kind_of: String, equal_to: ["Daily", "Hourly","MaxSize","Monthly","Weekly"]
attribute :logTargetW3C, kind_of: Integer, equal_to: [1, 2, 3]
