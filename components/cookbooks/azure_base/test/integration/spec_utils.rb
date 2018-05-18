class SpecUtils
  def initialize(node)
    @node = node
  end

  def get_cloud_name
    cloud_name = @node['workorder']['cloud']['ciName']
  end

  def get_provider
    cloud_name = get_cloud_name
    provider = @node['workorder']['services']['compute'][cloud_name]['ciClassName'].gsub("cloud.service.","").downcase.split(".").last
  end

  def get_cloud_service
    lb_service_type = @node['lb']['lb_service_type']
    cloud_service = @node['workorder']['services'][lb_service_type][get_cloud_name]

    cloud_service
  end
  def get_app_type
    @node['app_name']
  end
  def get_rfc_ci
    rfcCi = @node['workorder']['rfcCi']
    rfcCi
  end
  def get_ns_path_parts
    rfcCi = get_rfc_ci
    nsPathParts = rfcCi['nsPath'].split("/")
    nsPathParts
  end
  def get_service
    cloud_name = get_cloud_name
    app_type = get_app_type
    svc = case app_type
            when 'lb'
              @node['workorder']['services']['lb'][cloud_name]['ciAttributes']
            when 'fqdn'
              @node['workorder']['services']['dns'][cloud_name]['ciAttributes']
            when 'storage'
              @node['workorder']['services']['storage'][cloud_name]['ciAttributes']
            else
              @node['workorder']['services']['compute'][cloud_name]['ciAttributes']
          end
  end
  def get_location
    app_type = get_app_type
    svc = get_service

    location = case app_type
                 when 'lb', 'fqdn'
                   svc['location']
                 when 'storage'
                   svc['region']
                 else
                   svc['location']
               end
    location
  end
  def get_image_id
    #image_id is a calculated attributed. This is calculated in Compute::node_lookup recipe
    os = nil
    ostype = "default-cloud"

    cloud_name = get_cloud_name
    cloud = @node['workorder']['services']['compute'][cloud_name]['ciAttributes']
    rfcCi = get_rfc_ci

    if @node['workorder']['payLoad'].has_key?("os")
      os = @node['workorder']['payLoad']['os'].first
      ostype = os['ciAttributes']['ostype']
    else
      if ostype == "default-cloud"
        ostype = cloud['ostype']
      end
    end

    sizemap = JSON.parse( cloud['sizemap'] )
    imagemap = JSON.parse( cloud['imagemap'] )
    size_id = sizemap[rfcCi["ciAttributes"]["size"]]

    image_id = ''
    if !os.nil? && os['ciAttributes'].has_key?("image_id") && !os['ciAttributes']['image_id'].empty?
      image_id = os['ciAttributes']['image_id']
    else
      image_id = imagemap[ostype]
    end

    image_id
  end
  def get_server_name
    rfcCi = get_rfc_ci
    nsPathParts = get_ns_path_parts


    server_name = @node['workorder']['box']['ciName']+'-'+nsPathParts[3]+'-'+nsPathParts[2]+'-'+nsPathParts[1]+'-'+ rfcCi["ciId"].to_s
    if(server_name.size > 63)
      server_name = server_name.slice(0,63-(rfcCi["ciId"].to_s.size)-1)+'-'+ rfcCi["ciId"].to_s
    end

    server_name
    end
end
