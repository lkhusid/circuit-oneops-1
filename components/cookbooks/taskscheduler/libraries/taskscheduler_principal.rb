require 'ostruct'
require_relative "ext_string"
require_relative "ext_kernel"

module OO
  class TaskScheduler
    class Principal

      silence_warnings { PRINCIPAL_PROPERTIES = %w{user_id} }

      def initialize task_definition
        @task_definition = task_definition.Principal
      end


      def attributes
        attributes = {}
        PRINCIPAL_PROPERTIES.each { |property| attributes[property] = @task_definition.send(property.camelize) }
        OpenStruct.new(attributes)
      end

      def assign_attributes principal_attributes
        PRINCIPAL_PROPERTIES.each { |property| @task_definition.send(property.camelize << '=', principal_attributes[property]) if principal_attributes.has_key? (property) }
      end

    end
  end
end
