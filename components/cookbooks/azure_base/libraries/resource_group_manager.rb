require File.expand_path('../../libraries/azure_base_manager.rb', __FILE__)
require File.expand_path('../../libraries/logger.rb', __FILE__)
require File.expand_path('../../libraries/utils.rb', __FILE__)

module AzureBase
  # class to handle operations on the Azure Resource Group
  # this is the base class, other classes will extend
  class ResourceGroupManager < AzureBase::AzureBaseManager
    attr_accessor :rg_name,
                  :org,
                  :assembly,
                  :environment,
                  :platform_ci_id,
                  :location,
                  :subscription,
                  :resource_client,
                  :environment_ci_id,
                  :is_new_cloud

    def initialize(node)
      super(node)

      # get the info needed to get the resource group name
      nsPathParts = node['workorder']['rfcCi']['nsPath'].split('/')
      @org = nsPathParts[1]
      @assembly = nsPathParts[2]
      @environment = nsPathParts[3]
      @platform_ci_id = node['workorder']['box']['ciId']
      @environment_ci_id = node['workorder']['payLoad']['Environment'][0]['ciId']
      @is_new_cloud = Utils.is_new_cloud(node)
      if !@service['location'].nil?
        @location = @service['location']
      elsif !@service['region'].nil?
        @location = @service['region']
      end
      @subscription = @service['subscription']

      @rg_name = get_name
      @resource_client = Fog::Resources::AzureRM.new(@creds)
    end

    # this method will create/update the resource group with the info passed in
    def add
      begin
        # get the name
        @rg_name = get_name if @rg_name.nil?
        OOLog.info("RG Name is: #{@rg_name}")
        OOLog.info("New  cloud Pattern or old: #{@is_new_cloud}")
        # check if the rg is there
        if !exists?
          OOLog.info('RG does NOT exists.  Creating...')
          @resource_client.resource_groups.create(name: @rg_name, location: @location)
        else
          OOLog.info("Resource Group, #{@rg_name} already exists.  Moving on...")
        end
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error creating resource group: #{e.body}")
      rescue => ex
        OOLog.fatal("Error creating resource group: #{ex.message}")
      end
    end

    # This method will retrieve the resource group from azure.
    # if the resource group is not found it will return a nil.
    def exists?
      begin
        @resource_client.resource_groups.check_resource_group_exists(@rg_name)
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error checking resource group: #{@rg_name}. Exception: #{e.body}")
      rescue => ex
        OOLog.fatal("Error checking resource group: #{ex.message}")
      end
    end

    # This method will delete the resource group
    def delete
      rg_exists = @resource_client.resource_groups.check_resource_group_exists(@rg_name)
      if !rg_exists
        OOLog.info("The Resource Group #{@rg_name} does not exist. Moving on...")
      else
        @resource_client.resource_groups.get(@rg_name).destroy
      end
    end

    def list_resources
      require 'azure_mgmt_resources'

      token_provider = MsRestAzure::ApplicationTokenProvider.new(@creds[:tenant_id], @creds[:client_id], @creds[:client_secret])
      credentials = MsRest::TokenCredentials.new(token_provider)
      client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
      client.subscription_id = @creds[:subscription_id]

      client.resource_groups.list_resources(@rg_name)
    end

    # This method will get the resource group
    def get
      begin
        @resource_client.resource_groups.get(@rg_name)
      rescue MsRestAzure::AzureOperationError => e
        OOLog.fatal("Error getting resource group: #{e.body}")
      rescue => ex
        OOLog.fatal("Error getting resource group: #{ex.message}")
      end
    end

    # this method will return the resource group and availability set names
    # in the correct format
    # There is a hard limit of 64 for the name in azure, so we are taking
    # 15 chars from org, assembly, env, and abbreviating the location
    # The reason we include org/assembly/env/platform/location in the name of
    # the resource group is; we needed something that would be unique for an org
    # accross the whole subscription, we want to be able to provision and
    # de-provision platforms in the same assembly / env / location without
    # destroying all of them together.
    def get_name

      if @is_new_cloud
        @org[0..15] + '-' +
            @assembly[0..15] + '-' +
            @environment_ci_id.to_s + '-' +
            @environment[0..15] + '-' +
            Utils.abbreviate_location(@location)

      else

        @org[0..15] + '-' +
            @assembly[0..15] + '-' +
            @platform_ci_id.to_s + '-' +
            @environment[0..15] + '-' +
            Utils.abbreviate_location(@location)
      end
    end
  end
end
