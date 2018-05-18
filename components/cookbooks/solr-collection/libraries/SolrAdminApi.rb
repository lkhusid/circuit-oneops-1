#
# Cookbook Name :: solr-collection
# Library :: SolrAdminApi
#
# A utility module to deal with helper methods.
#

module SolrAdminApi

  module CollectionUtil

    require 'json'
    require 'net/http'
    require 'cgi'
    require 'rubygems'

    include Chef::Mixin::ShellOut


    # Common api to send the collection admin api requests
    def collectionApi(host_name,port,params,config_name=nil,path="/solr/admin/collections")
      if not config_name.nil?
        path = "#{path}?".concat(params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&'))+"&collection.configName="+config_name+"&wt=json"
      else
        path = "#{path}?".concat(params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&'))+"&wt=json"
      end

      Chef::Log.info(" HostName = " + host_name + ", Port = " + port + ", Path = " + path)
      http = Net::HTTP.new(host_name, port)
      req = Net::HTTP::Get.new(path)

      SolrAuth::AuthUtils.add_credentials_if_required(req)

      response = http.request(req)

      if response != nil then
        return JSON.parse(response.body())
      end
      raise StandardError, "empty response"
    end

    # Validate the schema action is valid
    def validateSchemaAction(schema_action)
      schema_actions = [ "add-field",
        "delete-field",
        "replace-field",
        "add-dynamic-field",
        "delete-dynamic-field",
        "replace-dynamic-field",
        "add-field-type",
        "delete-field-type",
        "replace-field-type",
        "add-copy-field",
        "delete-copy-field"
      ]

      if not schema_actions.include?(schema_action)
        raise "Unsupported schema action"
      else
        Chef::Log.info(schema_action + " schema action is a valid.")
      end

    end

    # Validate the json object
    def validateJsonPayload(json)
      begin
        json = JSON.parse(json)
        Chef::Log.info("valid json")
        return json
      rescue Exception => e
        raise "Invalid Json String"
      end
    end

  end
end


