#
# Cookbook Name :: solrcloud
# Library :: CloudProvider

require 'json'

# This class is used to implement cloud provider specific code. 
class CloudProvider
  
  def initialize(node)
    #get the current node's cloud name
    @cloud_name = node[:workorder][:cloud][:ciName]
    Chef::Log.info("@cloud_name : #{@cloud_name}")
    
    @cloud_provider = self.class.get_cloud_provider_name(node)
    Chef::Log.info("Initializing Cloud Provider : #{@cloud_provider}")
    
    # Replica distribution varies based on cloud provider. For ex. with 'Openstack' cloud provider, we distribute replicas across clouds and witn 'Azure', 
    # replicas are distributes across domains. If no cloud provider in payload, then error out. 
    if @cloud_provider == nil || @cloud_provider.empty?
      raise "Replica distribution varies based on cloud provider and hence cloud provider must be present in compute service at cloud level."
    end
    #get the current node's compute
    managedVia_compute = node.workorder.payLoad.ManagedVia[0]
   
    case @cloud_provider
      when /azure/
      # get zone info for 'azure' cloud provider
        zone = (managedVia_compute[:ciAttributes].has_key?"zone")?JSON.parse(managedVia_compute[:ciAttributes][:zone]):{}
        Chef::Log.info("zone = #{zone.to_json}")
        if zone == nil
          raise "Missing zone information for azure cloud at compute."
        end
        @fault_domain = zone['fault_domain']
        @update_domain = zone['update_domain']
        if @fault_domain == nil || @fault_domain.to_s.empty?
          raise "Missing fault_domain information for azure cloud at compute."
        end
        if @update_domain == nil || @update_domain.to_s.empty?
          raise "Missing update_domain information for azure cloud at compute."
        end
        @zone_name = "#{@fault_domain}___#{@update_domain}"
        Chef::Log.info("@zone_name : #{@zone_name}")
        # in case of azure, key -> fault_domain
        @zone_to_compute_ip_map = get_fault_domain_to_compute_ip_map(node)
      else #/vagrant/
        # in case of other (openstack), key -> cloud_name ex. prod-cdc5
        @zone_to_compute_ip_map = get_cloud_name_to_compute_ip_map(node)
    end
  end

  # get cloud name and computes information from the payload
  # where key-> <cloud_name> & value-> list of ips
  # For ex. {"prod-cdc5":[ip1, ip2],"prod-cdc6":[ip3, ip4]}
  def get_cloud_name_to_compute_ip_map(node)
    clouds = get_clouds_payload(node)
    Chef::Log.info("clouds = #{clouds.to_json}")
   
    #cloud_id_to_name_map=> {'35709237':'cloud1','35709238':'cloud2'}
    cloud_id_to_name_map = Hash.new
    clouds.each { |cloud|
      cloud_id_to_name_map[cloud[:ciId].to_s] = cloud[:ciName]
    }
    Chef::Log.info "cloud_id_to_name_map = #{cloud_id_to_name_map.to_json}"

    cloud_name_to_ip_map = Hash.new()
    computes = self.class.get_computes_payload(node)
    computes.each do |compute|
      
      # compute[:ciName] == nil meaning compute has not provisioned yet
      next if compute[:ciName].nil?
      # Example compute[:ciName]:  compute-35709237-2

      # extract cloud_id from compute ciName. i.e. cloud_id = 35709237
      cloud_id = compute[:ciName].split('-').reverse[1].to_s

      # get cloud_name for cloud_id from cloud_id_to_name_map. i.e. cloud_name = cloud1
      cloud_name = cloud_id_to_name_map[cloud_id]

      if (cloud_name_to_ip_map[cloud_name] == nil)
        cloud_name_to_ip_map[cloud_name] = Array.new
      end

      # add private_ip to cloud_name_to_ip_map
      if compute[:ciAttributes][:private_ip] != nil
        cloud_name_to_ip_map[cloud_name].push(compute[:ciAttributes][:private_ip])
      end
    end
    Chef::Log.info("cloud_name_to_ip_map: #{cloud_name_to_ip_map.to_json}")
    return cloud_name_to_ip_map
  end

  # get fault domain and computes map information from the payload
  #[
  #  {
  #    "ciAttributes": {
  #      "private_ip": "ip1",
  #      "zone": {
  #        "fault_domain": 0,
  #        "update_domain": 1
  #      }
  #    }
  #  },
  #  {
  #    "ciAttributes": {
  #      "private_ip": "ip2",
  #      "zone": {
  #        "fault_domain": 1,
  #        "update_domain": 2
  #      }
  #    }
  #  },
  #  {
  #    "ciAttributes": {
  #      "private_ip": "ip3",
  #      "zone": {
  #        "fault_domain": 0,
  #        "update_domain": 3
  #      }
  #    }
  #  },
  #  {
  #    "ciAttributes": {
  #      "private_ip": "ip4",
  #      "zone": {
  #        "fault_domain": 1,
  #        "update_domain": 4
  #      }
  #    }
  #  }
  #]
  # This method returns the result as {0=>["ip1","ip3"],1=>["ip2","ip4"]}
  def get_fault_domain_to_compute_ip_map(node)
    
    fault_domain_to_ip_map = Hash.new
    computes = self.class.get_computes_payload(node)

    computes.each do |compute|
      next if compute[:ciAttributes][:private_ip].nil?
      if zone_info_missing?(compute)
        raise "Zone attrribute with fault_domain/update_domain information is required."
      end
      zone  = JSON.parse(compute['ciAttributes']['zone'])
      fault_domain = zone['fault_domain']
      if !fault_domain_to_ip_map.has_key?fault_domain
        fault_domain_to_ip_map[fault_domain] = []
      end
      fault_domain_to_ip_map[fault_domain].push compute[:ciAttributes][:private_ip]
    end
    
    Chef::Log.info("fault_domain_to_ip_map = #{fault_domain_to_ip_map.to_json}")
    return fault_domain_to_ip_map
  end
  
  def get_zone_to_compute_ip_map()
    return @zone_to_compute_ip_map
  end

  # check if 'zone' attribute and/or its details are missing at compute
  def zone_info_missing?(compute)
    # check if 'zone' attribute is missing at compute
    if compute['ciAttributes']['zone'].nil?
      return true
    end
    # check if 'fault_domain' or 'update_domain' attribute is null/empty at
    zone  = JSON.parse(compute['ciAttributes']['zone'])
    if zone['fault_domain'].nil? || zone['fault_domain'] == '' || zone['update_domain'].nil? || zone['update_domain'] == ''
      return true
    end
    return false
  end

  # get <fault_domain>_<update_domain> from compute
  def get_zone_info(compute)
    zone  = JSON.parse(compute['ciAttributes']['zone'])
    return "#{zone['fault_domain']}_#{zone['update_domain']}"
  end

  # get compute payload from workorder
  def self.get_computes_payload(node)
    return node.workorder.payLoad.has_key?("RequiresComputes") ? node.workorder.payLoad.RequiresComputes : node.workorder.payLoad.computes
  end
  
  # This method may be called from solrcloud or solr-collection recipe and both resources in pack has cloud payload with
  # different names. for ex. solrcloud's cloud payload has name 'CloudPayload' & solr-collection's cloud payload is 'Clouds'
  # hence it should fetch the payload with name 'Clouds' if it exists otherwise 'CloudPayload'
  def get_clouds_payload(node)
    return node.workorder.payLoad.has_key?("Clouds") ? node.workorder.payLoad.Clouds : (node.workorder.payLoad.has_key?("CloudPayload") ? node.workorder.payLoad.CloudPayload : nil)
  end
  
  #extract cloud provider 'Openstack/Azure' from compute service string {"prod-cdc5":{"ciClassName":"cloud.service.Openstack"}}
  def self.get_cloud_provider_name(node)
    #Chef::Log.info("node[:workorder][:services][:compute] = #{node[:workorder][:services][:compute].to_json}")
    cloud_name = node[:workorder][:cloud][:ciName]
    if !node[:workorder][:services].has_key?("compute")
      error = "compute service is missing in the cloud services list, please make sure to do pull pack and design pull so that compute service becomes available"
      puts "***FAULT:FATAL=#{error}"
      raise error
    end
    cloud_provider_name = node[:workorder][:services][:compute][cloud_name][:ciClassName].gsub("cloud.service.","").downcase.split(".").last
    Chef::Log.info("Cloud Provider: #{cloud_provider_name}")
    return cloud_provider_name
  end
  
  # In case of Azure, this method validates if 'volume-blockstorage' mount point is set as 'installation_dir_path' from solrcloud and 'volume-app'
  # is set to something other than 'installation_dir_path' which will not be used
  def self.enforce_storage_use(node, blockstorage_mount_point, volume_app_mount_point)
    Chef::Log.info("blockstorage_mount_point = #{blockstorage_mount_point}")
    Chef::Log.info("volume_app_mount_point = #{volume_app_mount_point}")
    # For example expected blockstorage_mount_point is '/app/' which is expected to be same as installation dir on solrcloud attr
    if blockstorage_mount_point == nil || blockstorage_mount_point.empty?
      error = "Blockstorage is not selected. It is required on azure. Please add volume-blockstorage with correct mount point & storage if not added already or If you still want to use ephemeral, please select the flag 'Allow ephemeral on Azure' in solrcloud component"
      puts "***FAULT:FATAL=#{error}"
      raise error
    end
      
    # For azure, we want to set '/app/' as storage mount point so that all binaries, logs & data are kept on block storage
    installation_dir_path = node["installation_dir_path"] # expected as '/app'
    #remove all '/' from installation_dir_path & blockstorage_mount_point. For. ex. '/app/' => 'app' 
    volume_app = volume_app_mount_point.delete '/'
    installation_dir = installation_dir_path.delete '/'
    blockstorage_dir = blockstorage_mount_point.delete '/'
    
    if volume_app == installation_dir
      error = "On azure, ephemeral is not used and blockstorage will be used to store data as well as logs & binaries. Hence please change the mount point on volume-app to something other than '#{installation_dir_path}' for example `/app-not-used/` and mount pount on volume-blockstorage to '#{installation_dir_path}'"
      puts "***FAULT:FATAL=#{error}"
      raise error
    end
    
    if blockstorage_dir != installation_dir
      error = "Blockstorage mount point must be same as solrcloud installation dir i.e. /#{installation_dir_path}/."
      puts "***FAULT:FATAL=#{error}"
      raise error
    end
  end
    
end

