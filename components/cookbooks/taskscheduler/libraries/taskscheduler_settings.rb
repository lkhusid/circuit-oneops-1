require 'ostruct'
require_relative "ext_string"
require_relative "ext_kernel"

module OO
  class TaskScheduler
    class Settings

      silence_warnings { SETTINGS_PROPERTIES = %w{execution_time_limit} }

      def initialize task_definition
        @task_settings = task_definition.Settings
      end

      def attributes
        attributes = {}
        SETTINGS_PROPERTIES.each {|property| attributes[property] = @task_settings.send(property.camelize)}
        OpenStruct.new(attributes)
      end

      def assign_attributes settings_attributes
        @task_settings.StartWhenAvailable = true
        @task_settings.Enabled = true
        @task_settings.Hidden = false
        @task_settings.ExecutionTimeLimit = settings_attributes['execution_time_limit'] if settings_attributes.has_key? ('execution_time_limit')
      end

    end
  end
end
