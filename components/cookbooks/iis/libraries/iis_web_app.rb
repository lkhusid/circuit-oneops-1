require "ostruct"
require_relative "ext_kernel"
require_relative "iis_virtual_directory"

module OO
  class IIS
    class WebSite
      class WebApp

        def initialize(application)
          @application = application || OpenStruct.new
          reload
        end

        def reload
          @virtual_directory_collection = @application.Collection
        end

        def create(attributes)
          @application.Properties.Item("path").Value = attributes["application_path"]
          assign_attributes_to_application(attributes)
        end

        def update(attributes)
           assign_attributes_to_application(attributes)
        end

        def application_attributes
          attributes = {}
          attributes["application_pool"] = @application.Properties.Item("applicationPool").Value
          attributes["application_path"] = @application.Properties.Item("Path").Value
          virtual_directory_attributes = []
          (0..(@virtual_directory_collection.Count-1)).each do |index|
            virtual_directory_element = @virtual_directory_collection[index]
            virtual_directory_attributes << VirtualDirectory.new(virtual_directory_element).get_attributes
          end
          attributes["virtual_directories"] = virtual_directory_attributes
          attributes
        end

        def get_virtual_directory_position(path)
          (0..(@virtual_directory_collection.Count-1)).find { |i| @virtual_directory_collection.Item(i).Properties.Item("path").Value == path }
        end

        def virtual_directory_exists?(path)
          !get_virtual_directory_position(path).nil?
        end

        def create_virtual_directory(attributes)
          reload
          virtual_directory_element = @virtual_directory_collection.CreateNewElement("virtualDirectory")
          VirtualDirectory.new(virtual_directory_element).create(attributes)
          @virtual_directory_collection.AddElement(virtual_directory_element)
        end

        def update_virtual_directory(attributes)
          reload
          virtual_directory_element = @virtual_directory_collection.Item(get_virtual_directory_position(attributes["virtual_directory_path"]))
          VirtualDirectory.new(virtual_directory_element).update(attributes)
        end

        def delete_virtual_directory(path)
          reload
          @virtual_directory_collection.DeleteElement(get_virtual_directory_position(path)) if virtual_directory_exists?(path)
        end

        def assign_attributes_to_application(attributes = {})
          @application.Properties.Item("applicationPool").Value = attributes["application_pool"] if attributes.has_key?("application_pool")
          if attributes.has_key?("virtual_directory")
            virtual_directory_attributes = attributes["virtual_directory"]
            action = virtual_directory_exists?(virtual_directory_attributes["virtual_directory_path"]) ? "update_virtual_directory" : "create_virtual_directory"
            self.send(action, virtual_directory_attributes)
          end
        end

        private :assign_attributes_to_application
      end
    end
  end
end
