require File.expand_path('../../libraries/logger.rb', __FILE__)

module Utils

  # method to get credentials in order to call Azure
  def get_credentials(tenant_id, client_id, client_secret)
    begin
      # Create authentication objects
      token_provider =
          MsRestAzure::ApplicationTokenProvider.new(tenant_id,
                                                    client_id,
                                                    client_secret)

      OOLog.fatal('Azure Token Provider is nil') if token_provider.nil?

      MsRest::TokenCredentials.new(token_provider)
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("Error acquiring a token from Azure: #{e.body}")
    rescue => ex
      OOLog.fatal("Error acquiring a token from Azure: #{ex.message}")
    end
  end

  # if there is an apiproxy cloud var define, set it on the env.
  def set_proxy(cloud_vars)
    cloud_vars.each do |var|
      if var[:ciName] == 'apiproxy'
        ENV['http_proxy'] = var[:ciAttributes][:value]
        ENV['https_proxy'] = var[:ciAttributes][:value]
      end
    end
  end

  # if there is an apiproxy cloud var define, set it on the env.
  def set_proxy_from_env(node)
    cloud_name = node['workorder']['cloud']['ciName']
    compute_service =
        node['workorder']['services']['compute'][cloud_name]['ciAttributes']
    OOLog.info("ENV VARS ARE: #{compute_service['env_vars']}")
    env_vars_hash = JSON.parse(compute_service['env_vars'])
    OOLog.info("APIPROXY is: #{env_vars_hash['apiproxy']}")

    if !env_vars_hash['apiproxy'].nil?
      ENV['http_proxy'] = env_vars_hash['apiproxy']
      ENV['https_proxy'] = env_vars_hash['apiproxy']
    end
  end

  def get_component_name(type, ciId, platform_ci_id = nil)
    ciId = ciId.to_s
    unless platform_ci_id.nil?
      return "nic-#{platform_ci_id}-#{ciId}" if type == "nic"
    end
    if type == "nic"
      return "nic-" + ciId
    elsif type == "publicip"
      return "publicip-" + ciId
    elsif type == "privateip"
      return "nicprivateip-" + ciId
    elsif type == "lb_publicip"
      return "lb-publicip-" + ciId
    elsif type == "ag_publicip"
      return "ag_publicip-" + ciId
    end
  end

  def get_dns_domain_label(platform_name, cloud_id, instance_id, subdomain)
    subdomain = subdomain.gsub(".", "-")
    return (platform_name + "-" + cloud_id + "-" + instance_id.to_s + "-" + subdomain).downcase
  end

  # this is a static method to generate a name based on a ciId and location.
  def abbreviate_location(region)
    abbr = ''

    # Resouce Group name can only be 90 chars long.  We are doing this case
    # to abbreviate the region so we don't hit that limit.
    case region
      when 'eastus2'
        abbr = 'eus2'
      when 'centralus'
        abbr = 'cus'
      when 'brazilsouth'
        abbr = 'brs'
      when 'centralindia'
        abbr = 'cin'
      when 'eastasia'
        abbr = 'eas'
      when 'eastus'
        abbr = 'eus'
      when 'japaneast'
        abbr = 'jpe'
      when 'japanwest'
        abbr = 'jpw'
      when 'northcentralus'
        abbr = 'ncus'
      when 'northeurope'
        abbr = 'neu'
      when 'southcentralus'
        abbr = 'scus'
      when 'southeastasia'
        abbr = 'seas'
      when 'southindia'
        abbr = 'sin'
      when 'westeurope'
        abbr = 'weu'
      when 'westindia'
        abbr = 'win'
      when 'westus'
        abbr = 'wus'
      when 'ukwest'
        abbr = 'wuk'
      when 'uksouth'
        abbr = 'suk'
      else
        OOLog.fatal("Azure location/region, '#{region}' not found in Resource Group abbreviation List")
    end
    return abbr
  end

  def get_fault_domains(region)

    OOLog.info("Getting Fault Domain: #{region}")
# when new region added to oneops this fault domains needs to be updated
    fault_domains = {:eastus2 => 3, :southcentralus => 3, :westus => 3, :japanwest => 2, :japaneast => 2, :ukwest => 2, :uksouth => 2, :eastasia => 2, :default => -1}

    OOLog.info("Finished Fault Domain: #{region}")
    return fault_domains[region.to_sym].nil? ? fault_domains['default'.to_sym] : fault_domains[region.to_sym]
  end

  def get_update_domains

    return 20
  end

  def get_resource_tags(node)

    tags = {}

    azuretagkeys = ["applicationname", "notificationdistlist", "costcenter", "platform", "deploymenttype", "environmentinfo", "sponsorinfo", "ownerinfo"]

    org_tags = JSON.parse(node['workorder']['payLoad']['Organization'][0]['ciAttributes']['tags']).select {|k, v| azuretagkeys.include?(k)}
    assembly_tags = JSON.parse(node['workorder']['payLoad']['Assembly'][0]['ciAttributes']['tags']).select {|k, v| azuretagkeys.include?(k)}
    assembly_owner_tag = node['workorder']['payLoad']['Assembly'][0]['ciAttributes']["owner"] || "Unknown"

    tags.merge!(org_tags)
    tags.merge!(assembly_tags)
    tags['owner'] = assembly_owner_tag

    return tags
  end

  def is_new_cloud(node)
    cloud_name = node['workorder']['cloud']['ciName']
    cloud_name =~ /^(dev|prod|stg)-az-(\S*)-\d*$/ ? true : false
  end

  def get_nsg_rg_name(location)
    "#{location.upcase}_NSGs_RG"
  end

  def get_nsg_name(node)
    "#{get_pack_name(node)}_nsg_v#{current_time}"
  end

  def get_pack_name(node)
    node['workorder']['box']['ciAttributes']['pack']
  end

  def current_time
    time = Time.now.to_f.to_s
    time.split(/\W+/).join
  end

  # This method is to get the resource group for action work orders
  def get_resource_group(node, org, assembly, platform_ciID, environment, location, environment_ciID)

    new_cloud = is_new_cloud(node)
    OOLog.info("Resource Group org: #{org}")
    OOLog.info("Resource Group assembly: #{assembly}")
    OOLog.info("Resource Group Environment: #{environment}")
    OOLog.info("Resource Group location: #{location}")

    if new_cloud

      OOLog.info("Resource Group Environment ci ID: #{environment_ciID}")

      resource_group_name = org[0..15] + '-' +
          assembly[0..15] + '-' +
          environment_ciID.to_s + '-' +
          environment[0..15] + '-' +
          Utils.abbreviate_location(location)

    else

      OOLog.info("Resource Group Platform ci ID: #{platform_ciID}")

      resource_group_name = org[0..15] + '-' +
          assembly[0..15] + '-' +
          platform_ciID.to_s + '-' +
          environment[0..15] + '-' +
          Utils.abbreviate_location(location)
    end
    OOLog.info("Resource Group Name is: #{resource_group_name}")
    OOLog.info("Resource Group Name Length: #{resource_group_name.length}")

    resource_group_name
  end

  module_function :get_credentials,
                  :set_proxy,
                  :set_proxy_from_env,
                  :get_component_name,
                  :get_dns_domain_label,
                  :abbreviate_location,
                  :get_fault_domains,
                  :get_update_domains,
                  :get_resource_tags,
                  :is_new_cloud,
                  :get_resource_group,
                  :get_nsg_rg_name,
                  :get_nsg_name,
                  :get_pack_name

  end
