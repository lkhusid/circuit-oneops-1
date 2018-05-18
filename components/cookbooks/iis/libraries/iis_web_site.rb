require "ostruct"
require_relative "ext_kernel"
require_relative "iis_web_app"


module OO
  class IIS
    class WebSite

      class NullEntity < OpenStruct
        def nil?; true; end
        def Delete_(*attrs, &block); end
        def Count; 0; end
      end

      silence_warnings do
        SITE_SECTION = "system.applicationHost/sites"
        SITE = "Site"
      end

      def initialize(web_administration, name)
        @web_administration = web_administration
        @name = name
        reload
      end

      def reload
        @entity = @web_administration.find(SITE, @name) || NullEntity.new
        @web_site = get_website || NullEntity.new
      end

      def exists?
        not @entity.nil?
      end

      def app_virtual_path
        '/'
      end

      def start
        @entity.Start
      end

      def get_website
        @web_administration.readable_section_for(SITE_SECTION) do |section|
          collection = section.Collection
          position = (0..(collection.Count-1)).find { |i| collection.Item(i).GetPropertyByName("name").Value == @name }
          collection.Item(position) unless position.nil?
        end
      end

      def create(attributes)
        not exists? and @web_administration.perform { assign_attributes_on_create(attributes) }
      end

      def update(attributes)
        exists? and @web_administration.perform { assign_attributes_on_update(attributes) }
      end

      def delete
        @web_administration.delete(SITE, @name).tap { reload }
      end

      def application_exists?(path)
        app_position = get_application_position(path)
        !app_position.nil?
      end

      def get_application(path)
        app_position = get_application_position(path)
        applications = @web_site.Collection
        application_element = applications.Item(app_position)
        WebApp.new(application_element).application_attributes
      end

      def get_application_position(path)
        collection = @web_site.Collection
        (0..(collection.Count-1)).find { |i| collection.Item(i).Properties.Item("path").Value == path }
      end

      def create_application(attributes)
        @web_administration.application_writable_section_for(SITE_SECTION, @name) do |site|
          application_collection = site.Collection
          application_element = application_collection.CreateNewElement("application")
          WebApp.new(application_element).create(attributes)
          application_collection.AddElement(application_element)
        end
      end

      def update_application(attributes)
        @web_administration.application_writable_section_for(SITE_SECTION, @name) do |site|
          application_collection = site.Collection
          application_element = application_collection.Item(get_application_position(attributes["application_path"]))
          WebApp.new(application_element).update(attributes)
        end
      end

      def delete_application(path)
        @web_administration.application_writable_section_for(SITE_SECTION, @name) do |site|
          application_collection = site.Collection
          application_collection.DeleteElement(get_application_postion(path))
        end
      end

      def resource_needs_change(attributes)
        update_attributes = Hash.new({})
        bindings = []
        new_bindings = []
        @web_administration.readable_section_for(SITE_SECTION) do |section|
          collection = section.Collection
          position = (0..(collection.Count-1)).find { |i| collection.Item(i).GetPropertyByName("name").Value == @name }
          site = collection.Item(position)
          update_attributes["id"] = attributes["id"] unless site.Properties.Item("id").Value.equal?(attributes["id"])
          update_attributes["server_auto_start"] = attributes["server_auto_start"] unless site.Properties.Item("serverAutoStart").Value.equal?(attributes["server_auto_start"])

          bindings_collection = site.ChildElements.Item("bindings").Collection

          (0..(bindings_collection.Count-1)).each do |i|
            protocol_value = bindings_collection.Item(i).GetPropertyByName('protocol').Value
            binding_information_value = bindings_collection.Item(i).GetPropertyByName('bindingInformation').Value
            bindings = [{'protocol' => "#{protocol_value}", 'binding_information' => "#{binding_information_value}"}]
            if protocol_value == 'https'
              certificate_hash = bindings_collection.Item(i).GetPropertyByName('certificateHash').Value
              update_attributes["certificate_hash"] = attributes["certificate_hash"] if certificate_hash.downcase != attributes["certificate_hash"].downcase
            end
          end

          new_bindings = attributes["bindings"]
          update_attributes["bindings"] = attributes["bindings"] unless (bindings - new_bindings).empty?

          applications = site.Collection
          app_position = (0..(applications.Count-1)).find { |i| applications.Item(i).Properties.Item("path").Value == app_virtual_path }
          app_element = applications.Item(app_position)
          app_pool = app_element.GetPropertyByName("applicationPool").Value
          update_attributes["application_pool"] = attributes["application_pool"] if app_pool != attributes["application_pool"]

          virtual_dirs = app_element.Collection
          virtual_directory_position = (0..(virtual_dirs.Count-1)).find { |i| virtual_dirs.Item(i).Properties.Item("path").Value == app_virtual_path }
          virtual_directory = virtual_dirs.Item(virtual_directory_position)
          virtual_directory_physical_path = virtual_directory.GetPropertyByName("physicalPath").Value
          update_attributes["virtual_directory_physical_path"] = attributes["virtual_directory_physical_path"] if virtual_directory_physical_path != attributes["virtual_directory_physical_path"]

        end
        update_attributes.empty?
      end

      protected


      def assign_attributes_on_create(attributes)
        @web_administration.writable_section_for(SITE_SECTION) do |sites_section|
          sites_collection = sites_section.Collection
          site_element = sites_collection.CreateNewElement("site")
          site_element.Properties.Item("name").Value = @name
          site_element.Properties.Item("id").Value = attributes["id"]
          site_element.Properties.Item("serverAutoStart").Value = attributes["server_auto_start"]
          bindings_collection = site_element.ChildElements.Item("bindings").Collection
          attributes["bindings"].each do |site_binding|
            binding_element = bindings_collection.CreateNewElement("binding")
            binding_element.Properties.Item("protocol").Value = site_binding["protocol"]
            binding_element.Properties.Item("bindingInformation").Value = site_binding["binding_information"]
            bindings_collection.AddElement(binding_element)
            if site_binding["protocol"] == 'https' && !attributes["certificate_hash"].empty?
              add_ssl_certificate(binding_element, attributes)
            end
          end
          site_collection = site_element.Collection
          application_element = site_collection.CreateNewElement("application")
          application_element.Properties.Item("path").Value = app_virtual_path
          application_element.Properties.Item("applicationPool").Value = attributes["application_pool"]
          application_collection = application_element.Collection
          virtual_directory_element = application_collection.CreateNewElement("virtualDirectory")
          virtual_directory_element.Properties.Item("path").Value = app_virtual_path
          virtual_directory_element.Properties.Item("physicalPath").Value = attributes["virtual_directory_physical_path"]
          application_collection.AddElement(virtual_directory_element)
          site_collection.AddElement(application_element)
          sites_collection.AddElement(site_element)
        end
        reload
      end

      def assign_attributes_on_update(attributes)
        @web_administration.writable_section_for(SITE_SECTION) do |section|
          collection = section.Collection
          position = (0..(collection.Count-1)).find { |i| collection.Item(i).GetPropertyByName("name").Value == @name }
          site = collection.Item(position)
          site.Properties.Item("id").Value = attributes["id"] if attributes.has_key?("id")
          site.Properties.Item("serverAutoStart").Value = attributes["server_auto_start"] if attributes.has_key?("server_auto_start")
          if attributes.has_key?("bindings")
            bindings_collection = site.ChildElements.Item("bindings").Collection
            bindings_collection.Clear
            attributes["bindings"].each do |site_binding|
              binding_element = bindings_collection.CreateNewElement("binding")
              binding_element.Properties.Item("protocol").Value = site_binding["protocol"]
              binding_element.Properties.Item("bindingInformation").Value = site_binding["binding_information"]
              bindings_collection.AddElement(binding_element)
              if site_binding["protocol"] == 'https' && !attributes["certificate_hash"].empty?
                add_ssl_certificate(binding_element, attributes)
              end
            end
          end

          applications = site.Collection
          app_position = (0..(applications.Count-1)).find { |i| applications.Item(i).Properties.Item("path").Value == app_virtual_path }
          app_element = applications.Item(app_position)
          app_element.Properties.Item("applicationPool").Value = attributes["application_pool"] if attributes.has_key?("application_pool")

          virtual_dirs = app_element.Collection
          virtual_directory_position = (0..(virtual_dirs.Count-1)).find { |i| virtual_dirs.Item(i).Properties.Item("path").Value == app_virtual_path }
          virtual_directory = virtual_dirs.Item(virtual_directory_position)
          virtual_directory.Properties.Item("physicalPath").Value = attributes["virtual_directory_physical_path"] if attributes.has_key?("virtual_directory_physical_path")

        end
        reload
      end

      def add_ssl_certificate(binding_element, attributes)
        method_instance = binding_element.Methods.Item("AddSslCertificate").CreateInstance()
        method_instance.Input.Properties.Item("certificateHash").Value = attributes["certificate_hash"]
        method_instance.Input.Properties.Item("certificateStoreName").Value = attributes["certificate_store_name"];
        method_instance.Execute()
      end

    end
  end
end
