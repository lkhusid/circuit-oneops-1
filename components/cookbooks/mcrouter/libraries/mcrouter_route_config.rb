require 'json'

class Cloud
  attr_accessor :cloud_id, :ip, :ip_with_port, :compute_index, :is_active_cloud, :is_active_dc, :ci_name, :memcached_port, :mcrouter_port
end

module McrouterRouteConfig
  FAULT_DOMAIN_INFIX="FaultDomain"

  def self.get_mcrouter_cloud_config(node)
    if !node.workorder.has_key?("cloud")
      raise "Could key not found within workorder."
    end
    if !node.workorder.payLoad.has_key?("DependsOn")
      raise "DependsOn key not found within payload."
    end

    @@pool_group_by = node['mcrouter']['pool_group_by']
    memcached=node.workorder.payLoad.DependsOn.select{ |d| d['ciClassName'] =~ /Memcached/ }

    mcrouter_port=5000
    memcached_port = nil
    memcached.each { |n|
      memcached_port = n[:ciAttributes].has_key?("port") ? n[:ciAttributes][:port] : 11211
    }

    current_cloud_id   = node.workorder.cloud['ciId']
    current_cloud_id = exec_zone(current_cloud_id, (node.workorder.payLoad.has_key?("ManagedVia") ? node.workorder.payLoad.ManagedVia[0] : nil))

    cloud_dc = cloud_dc(node)
    cloud_computes = cloud_computes(node)
    clouds = extract_clouds(cloud_computes, current_cloud_id, memcached_port, mcrouter_port, cloud_dc)
    clouds = sort_pools(clouds)
    cloud_pools, cloud_hash_pools = build_pools(clouds)

    # Supported routes
    # PoolRoute (default) : Original route used by pack
    # HashRouteSalted : Use salted hash to server pool 

    cloud_routes=[]
    if node['mcrouter']['route'] =='PoolRoute'
      cloud_routes=build_routes(cloud_pools)
    elsif node['mcrouter']['route'] =='HashRouteSalted'
      cloud_routes=build_routes_hashroute_salted(cloud_pools)
    else
      raise "Unknown route: #{node['mcrouter']['route']}"
    end

    # Supported data policies
    # AllAsyncRoute (default) : get/gets uses MissFailoverRoute, all other operations use AllAsyncRoute
    # AllSyncRoute : get/gets uses MissFailoverRoute, all other operations use AllSyncRoute
    # AllInitialRoute : get/gets uses MissFailoverRoute, all other operations use AllInitialRoute
    # AllFastestRoute : get/gets uses MissFailoverRoute, all other operations use AllFastestRoute
		# AllMajorityRoute : get/gets uses MissFailoverRoute, all other operations use AllMajorityRoute
		#
    if node['mcrouter']['policy'] != 'AllSyncRoute' &&
        node['mcrouter']['policy'] != 'AllAsyncRoute' &&
				node['mcrouter']['policy'] != 'AllInitialRoute' &&
				node['mcrouter']['policy'] != 'AllFastestRoute' &&
				node['mcrouter']['policy'] != 'AllMajorityRoute'
      raise "Unknown Data Consistency Policy: #{node['mcrouter']['policy']}"
    end

    miss_limit = node['mcrouter']['miss_limit'].to_i
    miss_limit = 999 unless miss_limit > 0

    return JSON.pretty_generate({
        'pools' => cloud_hash_pools,
        'route' => {
            'type' => 'OperationSelectorRoute',
            'default_policy' => {
                'type' => node['mcrouter']['policy'],
                'children' => cloud_routes
            },
            'operation_policies'=> {
                'get' => {
                    'type' => 'MissFailoverRoute',
                    'children' => cloud_routes.take(miss_limit)
                },
                'gets' => {
                    'type' => 'MissFailoverRoute',
                    'children' => cloud_routes.take(miss_limit)
                }
            }
        }
    })
  end

  def self.exec_zone(cloud_id, compute)
    if @@pool_group_by == "CloudFaultDomain"
      zone = get_zone(compute)
      if !zone.nil?
        if zone.has_key?("fault_domain")
          cloud_id = zone ? "#{cloud_id}#{McrouterRouteConfig::FAULT_DOMAIN_INFIX}#{zone['fault_domain']}" : cloud_id
        end
      end
    end
    cloud_id
  end

  # build map for cloud id to dc name based on clouds list
  def self.cloud_dc(node)
    cloud_dc = {}
    if node.workorder.payLoad.has_key?('clouds')
      node.workorder.payLoad.clouds.each do |c|
        if c.has_key?('ciId') and c.has_key?('ciName')
          # Convert cloud name to dc by removing numbers. ex. prod-dal2 becomes prod-dal
          cloud_dc[c['ciId'].to_s] = c['ciName'].gsub(/\d+/, '')
        end
      end
    end
    cloud_dc
  end

  def self.cloud_computes(node)
    computes = node.workorder.payLoad.has_key?("RequiresComputes") ? node.workorder.payLoad.RequiresComputes : node.workorder.payLoad.computes
    cloud_computes = {}
    computes.each do |compute|
      next if compute[:ciAttributes][:public_ip].nil? || compute[:ciAttributes][:public_ip].empty?

      cloud_id = compute[:ciName].split('-').reverse[1]
      cloud_id_with_zones = exec_zone(cloud_id, compute)
      cloud_id = cloud_id_with_zones.nil? ? cloud_id : cloud_id_with_zones

      computeList = cloud_computes[cloud_id]
      if computeList == nil
        computeList = []
      end
      computeList.push compute
      cloud_computes[cloud_id] = computeList
    end
    cloud_computes
  end

  def self.get_zone(compute)
    zone=nil
    if (!compute.nil? && compute[:ciBaseAttributes].has_key?('zone') && !compute[:ciBaseAttributes][:zone].nil? && compute[:ciBaseAttributes][:zone].size > 2)
      zone=JSON.parse(compute[:ciBaseAttributes][:zone])
    elsif (!compute.nil? && compute[:ciAttributes].has_key?('zone') && !compute[:ciAttributes][:zone].nil? && compute[:ciAttributes][:zone].size > 2)
      zone=JSON.parse(compute[:ciAttributes][:zone])
    end
    zone
  end

  def self.build_routes(cloud_pools)
    cloud_routes=[]
    cloud_pools.each { |cloud_id, v|
      cloud_name="PoolRoute|#{cloud_id.keys.first}"
      cloud_routes.push(cloud_name)
    }
    cloud_routes
  end


  def self.build_routes_hashroute_salted(cloud_pools)
    cloud_routes=[]
    cloud_pools.each { |cloud_id|
      pool_name=cloud_id.keys.first
      salt=pool_name.split('-')[1]
      cloud_name={ "type" => "HashRoute", "children" => "Pool|#{pool_name}", "salt" => "#{salt}"} 
      cloud_routes.push(cloud_name)
    }
    cloud_routes
  end

  def self.sort_pools(clouds)
    # clouds array is an array of arrays.
    # We want to sort it so that all pools in the same dc are first with the rest stay at their current position.
    
    active_dc = []
    others    = []
    clouds.each do |cloud|
      if cloud.first.is_active_dc
        active_dc.push(cloud)
      else
        others.push(cloud)
      end
    end
    
    sorted_clouds = []
    active_dc.each { |c| sorted_clouds.push(c) }
    others.each    { |c| sorted_clouds.push(c) }
    
    sorted_clouds
  end
  
  def self.build_pools(clouds)
    cloud_pools=[]

    cloud_hash_pools={}
    index=1

    clouds.each { |cloud|
      cloud_id=nil
      current_cloud=[]
      is_active_cloud=false

      cloud.each { |c|
        #if c.is_current_cloud
        current_cloud.push("#{c.ip_with_port}")
        cloud_id=c.cloud_id
        is_active_cloud=c.is_active_cloud
        #end
      }
      cloud_index = is_active_cloud ? 0 : index
      cloud_pools[cloud_index]= {"cloud-#{cloud_id}" => {
          #memcached boxes
          'servers' =>
              current_cloud
      }}
      cloud_hash_pools.store( "cloud-#{cloud_id}", {
          #memcached boxes
          'servers' =>
              current_cloud
      })
      index = is_active_cloud ? index : (index+1)
    }
    return cloud_pools, cloud_hash_pools
  end

  def self.extract_clouds(cloud_computes, current_cloud_id, memcached_port, mcrouter_port, cloud_dc)
    current_cloud=[]
    other_clouds=[]
    temp_key=nil

    cloud_computes.sort.each do |key, value|
      value.each do |c|
        temp_key = temp_key == nil ? key : temp_key
        cc = set_cloud_computes(c, key, memcached_port, current_cloud_id, mcrouter_port, cloud_dc)

        if "#{temp_key}" == "#{key}"
          current_cloud.push cc
        else
          other_clouds.push current_cloud.sort_by { |c| c.compute_index }
          current_cloud=[]
          current_cloud.push cc
          temp_key=key
        end

      end
    end
    other_clouds.push current_cloud.sort_by { |c| c.compute_index }
    other_clouds
  end

  def self.set_cloud_computes(c, key, memcached_port, current_cloud_id, mcrouter_port, cloud_dc)
    cc=Cloud.new
    cc.cloud_id=key
    # current_cloud_id is of type Fixnum class, but key is String class
    cc.is_active_cloud = current_cloud_id.to_s == key ? true : false
    cc.is_active_dc = cloud_dc[current_cloud_id.to_s.gsub(/#{McrouterRouteConfig::FAULT_DOMAIN_INFIX}\d/, '')] == cloud_dc[key.gsub(/#{McrouterRouteConfig::FAULT_DOMAIN_INFIX}\d/, '')] ? true : false
    port = memcached_port
    cc.ip_with_port="#{c["ciAttributes"]["public_ip"]}:#{port}"
    cc.ip="#{c["ciAttributes"]["public_ip"]}"
    cc.memcached_port=memcached_port
    cc.mcrouter_port = mcrouter_port
    cc.compute_index=c[:ciName].split('-').reverse[0].to_i
    cc.ci_name=c[:ciName]
    cc
  end
end
