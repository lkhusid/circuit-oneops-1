
class Chef::Recipe::BaasJsonHelper

    require 'json'
    require 'fileutils'
    require 'rubygems'
  
    include Chef::Mixin::ShellOut
    
    # Returns the parsed json object if the input string is a valid json, else
    # returns the input by doing the type conversion. Currently boolean, float,
    # int and string types are supported. The type conversion is required for
    # yaml since the input from UI would always be string.
    #
    # @param json:: input json string
    #
    def self.parse_json (json)
      begin
        return JSON.parse(json)
      rescue Exception => e
        # Assuming it would be string.
        # Boolean type
        return true if  json =~ (/^(true)$/i)
        return false if  json =~ (/^(false)$/i)
        # Fixnum type
        return json.to_i if  (json.to_i.to_s == json)
        # Float type
        return json.to_f if  (json.to_f.to_s == json)
        return json
      end
    end
end
