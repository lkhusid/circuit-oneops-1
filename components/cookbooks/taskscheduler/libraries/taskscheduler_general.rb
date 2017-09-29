require 'ostruct'
require_relative "ext_string"
require_relative "ext_kernel"

module OO
  class TaskScheduler
    class General


      silence_warnings { GENERAL_PROPERTIES = %w{description} }

      def initialize task_definition
        @task_definition = task_definition.RegistrationInfo
      end


      def attributes
        attributes = {}
        GENERAL_PROPERTIES.each { |property| attributes[property] = @task_definition.send(property.camelize) }
        OpenStruct.new(attributes)
      end

      def assign_attributes general_attributes
        GENERAL_PROPERTIES.each { |property| @task_definition.send(property.camelize << '=', general_attributes[property]) if general_attributes.has_key? (property)  }
      end

    end
  end
end
