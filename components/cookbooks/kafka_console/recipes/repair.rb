cookbook_name = node.app_name.downcase

include_recipe 'kafka_console::restart'
