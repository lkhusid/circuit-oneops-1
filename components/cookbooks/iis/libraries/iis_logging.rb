module OO
  class IIS
    class Logging

      LOGGING_PROPERTIES = ["logFormat", "directory", "enabled", "period", "logTargetW3C"]
      SITE_SECTION = "system.applicationHost/sites"
      LOGGING_PERIOD = {
        0 => 'MaxSize',
        1 => 'Daily',
        2 => 'Weekly',
        3 => 'Monthly',
        4 => 'Hourly'
      }

      LOGGING_FORMAT = {
        0 => 'IIS',
        1 => 'NCSA',
        2 => 'W3C'
      }

      def initialize(web_administration, site_name)
        @web_administration = web_administration
        @site_name = site_name
      end

      def get_logging_item( section )
        collection = section.collection
        position = (0..(collection.Count-1)).find { |i| collection.Item(i).GetPropertyByName("name").Value == @site_name }
        site = collection.Item(position)
        site.ChildElements.Item("logFile")
      end

      def get_logging_attributes
        iis_logging_attributes = Hash.new({})
        @web_administration.readable_section_for(SITE_SECTION) do |section|
          log_file_item = get_logging_item( section )
          Chef::Log.info "The log file item is #{log_file_item} and value is #{log_file_item.Properties.Item("period").value}"

          LOGGING_PROPERTIES.each do |property|
            iis_logging_attributes[ property ] = log_file_item.Properties.Item(property).Value
          end
          iis_logging_attributes['period'] = LOGGING_PERIOD[iis_logging_attributes['period']]
          iis_logging_attributes['logFormat'] = LOGGING_FORMAT[iis_logging_attributes['logFormat']]
        end
        iis_logging_attributes
      end

      def assign_logging_attributes( logging_attributes )
         @web_administration.writable_section_for(SITE_SECTION) do |section|
           log_file_item = get_logging_item( section )
           LOGGING_PROPERTIES.each do |property|
             log_file_item.Properties.Item(property).Value = logging_attributes[ property ]
           end
         end
      end

    end
  end
end
