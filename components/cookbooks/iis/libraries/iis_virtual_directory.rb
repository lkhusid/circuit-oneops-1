module OO
  class IIS
    class WebSite
      class WebApp
        class VirtualDirectory

          def initialize(virtual_directory)
            @virtual_directory = virtual_directory
          end

          def get_attributes
            attributes = {}
            attributes["virtual_directory_path"] = @virtual_directory.Properties.Item("path").Value
            attributes["virtual_directory_physical_path"] = @virtual_directory.Properties.Item("physicalPath").Value
            attributes
          end

          def create(attributes = {})
            @virtual_directory.Properties.Item("path").Value = attributes["virtual_directory_path"]
            assign_attributes_to_virtual_directory(attributes)
          end

          def update(attributes = {})
            assign_attributes_to_virtual_directory(attributes)
          end

          def assign_attributes_to_virtual_directory(attributes)
            @virtual_directory.Properties.Item("physicalPath").Value  = attributes["virtual_directory_physical_path"]  if attributes.has_key?("virtual_directory_physical_path")
          end

        end
      end
    end
  end
end
