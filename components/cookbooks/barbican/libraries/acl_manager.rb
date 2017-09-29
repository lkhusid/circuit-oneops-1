require 'rest-client'

#require '/usr/local/share/gems/gems/fog-openstack-0.1.21/lib/fog/openstack.rb'
#require '/usr/local/share/gems/gems/fog-openstack-0.1.21/lib/fog/openstack/core.rb'

require 'fog'
require 'fog/openstack'
require 'fog/core'
require 'fog/openstack/core'

require 'json'
require 'excon'

class ACLManager
  def initialize(endpoint, username, password, tenantname)
    fail ArgumentError, 'tenant is nil' if tenantname.nil?

    @connection_params = {
        openstack_auth_url:     "#{endpoint}",
        openstack_username:     "#{username}",
        openstack_api_key:      "#{password}",
        openstack_project_name: "#{tenantname}",
        openstack_domain_id:    "default"

    }

  end

  def get_secret_acl(secret_uuid)

    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
    acl_obj = key_manager.get_secret_acl(secret_uuid)
    if !acl_obj.nil?
      return acl_obj
    end
  end

  def replace_secret_acl(secret_uuid, user_id_list)
    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
    uuid_list = get_uuid_list(user_id_list)
    data = {
        'read' => {
            'users'  => uuid_list,
            'project-access' => true
        }
    }
    response = key_manager.replace_secret_acl(secret_uuid,
                                              data)
    return response.data
  end

  def get_uuid_list(user_id_list)
    identity_manager = Fog::Identity::OpenStack.new(@connection_params)
    uuid_list = Array.new
    user_id_list.each do | user_name |
      response = identity_manager.get_user_by_name(user_name)
      data = response.data[:body]
      user_list = data['users']
      uuid_list.push(user_list[0]['id'])
    end
    uuid_list
  end

  def delete_secret_acl(secret_ref)
    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
    response = key_manager.delete_secret_acl secret_ref.split("/").last
    return response.data
  end


  def get_container_acl(secret_ref)
    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
    acl_obj = key_manager.get_container_acl(secret_ref.split("/").last)
    if !acl_obj.nil?
      return acl_obj
    end
  end


  def replace_container_acl(secret_uuid, user_id_list)
    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
    uuid_list = get_uuid_list(user_id_list)
    data = {
        'read' => {
            'users'  => uuid_list,
            'project-access' => true
        }
    }
    response = key_manager.replace_container_acl(secret_uuid,
                                                 data)
    return response.data
  end


  def delete_container_acl(secret_ref)
    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
    response = key_manager.delete_container_acl secret_ref.split("/").last
    return response.data
  end
end
