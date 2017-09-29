require 'ostruct'
require_relative "ext_string"
require_relative "ext_kernel"

module OO
  class TaskScheduler
    class Actions

      silence_warnings { ACTIONS_PROPERTIES = %w{path working_directory arguments} }

      def initialize task_definition
        @task_actions_definition = task_definition.Actions
      end

      def get_current_action
        @task_actions_definition.Count > 0 ? @task_actions_definition.Item(1) : @task_actions_definition.Create(0)
      end

      private :get_current_action

      def attributes
        attributes = {}
        actions = get_current_action
        ACTIONS_PROPERTIES.each {|property| attributes[property] = actions.send(property.camelize)}
        OpenStruct.new(attributes)
      end

      def assign_attributes actions_attributes
        actions = get_current_action
        ACTIONS_PROPERTIES.each { |property| actions.send(property.camelize << '=', actions_attributes[property]) if actions_attributes.has_key? (property) }
      end

    end
  end
end
