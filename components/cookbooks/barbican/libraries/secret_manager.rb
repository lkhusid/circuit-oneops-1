require 'rest-client'

#require '/usr/local/share/gems/gems/fog-openstack-0.1.21/lib/fog/openstack.rb'
#require '/usr/local/share/gems/gems/fog-openstack-0.1.21/lib/fog/openstack/core.rb'

require 'fog'
require 'fog/openstack'
require 'fog/core'
require 'fog/openstack/core'

require 'json'
require 'excon'


class SecretManager
  def initialize(endpoint, username, password, tenantname)
    fail ArgumentError, 'tenant is nil' if tenantname.nil?

    @connection_params = {
        openstack_auth_url:     "#{endpoint}",
        openstack_username:     "#{username}",
        openstack_api_key:      "#{password}",
        openstack_project_name: "#{tenantname}",
        openstack_tenant:       "#{tenantname}",
        openstack_domain_id:    "default"

    }

  end

  def create(secret)
    fail ArgumentError, 'secret is nil' if secret.nil?
    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)

    if get_secret(secret['name']) == false #check whether the secret with same name exist before creating new
      response = key_manager.create_secret  payload_content_type: secret['payload_content_type'],
                                              name: secret['name'],
                                              payload: secret['payload'],
                                              algorithm: secret['algorithm'],
                                              mode: secret['mode'],
                                              bit_length: 256

      secret_ref = (response.data[:body])['secret_ref']
      # Make fog call to create secrets
      if !secret_ref.nil?
        return secret_ref
      else
        return false
      end
    else
      Chef::Log.warn "Cannot create new secret, Using Secret #{secret['name']} existing already."
    end
  end

  def get_secret(secret_name)
    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
    response = (key_manager.list_secrets(limit: 10000000))
    secrets_list= Array.new
    secrets_list = (response.data[:body])['secrets']
    if !secrets_list.nil?
      secrets_list.each do |secret|
        if secret['name'] == secret_name
          return secret['secret_ref']
        end
      end
    else
      return false
    end
      return false
  end

  def delete(secret_ref)
    fail ArgumentError, 'secret_ref is nil' if secret_ref.nil? || secret_ref.empty?
    begin
      key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
      secret_obj = key_manager.secrets.get secret_ref
      if !secret_obj.nil?
        Chef::Log.info secret_obj.inspect
        delete_Result = secret_obj.destroy
        if !delete_Result.nil?
          if delete_Result
            Chef::Log.info "Succesfully deleted the secret"
            return true
          else
            Chef::Log.info "Failed to delete the secret"
            return false
          end
        end
      else
        Chef::Log.info "Cannot find the secret" + secret_ref
      end
    rescue Exception => e
      raise e.inspect
    end
  end

  def create_container(container_name, type, certificate, private_key, intermediates, passphrase)
    fail ArgumentError, 'container_name is nil' if container_name.nil? || container_name.empty?
    fail ArgumentError, 'certificate is nil' if certificate.nil? || certificate.empty?
    fail ArgumentError, 'private_key is nil' if private_key.nil? || private_key.empty?
    fail ArgumentError, 'intermediates is nil' if intermediates.nil? || intermediates.empty?

    begin
      Chef::Log.info("certificate: #{certificate}")
      Chef::Log.info("private_key: #{private_key}")
      Chef::Log.info("intermediates: #{intermediates}")
      Chef::Log.info("passphrase: #{passphrase}")

      cert_ref= get_secret(certificate)
      Chef::Log.info("cert_ref:#{cert_ref}")

      private_key_ref = get_secret(private_key)
      Chef::Log.info("private_key_ref:#{private_key_ref}")

      intermediates_ref = get_secret(intermediates)
      Chef::Log.info("intermediates_ref:#{intermediates_ref}")


      if cert_ref != false && private_key_ref != false && intermediates_ref != false

        certificate_hash ={
            name: "certificate",
            secret_ref: cert_ref
        }

        private_key_hash ={
            name: "private_key",
            secret_ref: private_key_ref
        }



        intermediates_hash ={
            name: "intermediates",
            secret_ref: intermediates_ref
        }

        secret_refs = Array.new
        secret_refs.push(certificate_hash)
        secret_refs.push(private_key_hash)
        secret_refs.push(intermediates_hash)

        if !passphrase.nil?
          private_key_passphrase_ref = get_secret(passphrase)
          Chef::Log.info("private_key_passphrase_ref:#{private_key_passphrase_ref}")
          private_key_passphrase_hash ={
              name: "private_key_passphrase",
              secret_ref: private_key_passphrase_ref
          }
          secret_refs.push(private_key_passphrase_hash)
        end


        if get_container(container_name) == false
        key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
        response = key_manager.create_container name: container_name,
                                                      type: type,
                                                      secret_refs: secret_refs
        container_obj_ref = (response.data[:body])['container_ref']
        Chef::Log.info(container_obj_ref.inspect)
        #Make fog call to create container
        if !container_obj_ref.nil?
          Chef::Log.info container_obj_ref.inspect
          return container_obj_ref
        else
          return false
        end

      else
        raise "Cannot create container, container with name #{container_name} already exists."
      end
      else

        raise "Cannot create container, one of the secret is missing"

      end
    rescue Exception => e
      raise e.inspect
    end
  end

  def delete_container(container_ref)
    begin
      key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
      container_obj = key_manager.containers.get container_ref
      if !container_obj.nil?
        puts container_obj.inspect
        delete_Result = container_obj.destroy
        if !delete_Result.nil?
          if delete_Result
            Chef::Log.info "Succesfully deleted the container"
            return true
          else
            Chef::Log.info "Failed to delete the container"
            return false
          end
        end
        return false
      else
        raise "Cannot find the ref #{container_ref}"
      end
    rescue Exception => e
      raise e.inspect
    end
  end

  def get_container(container_name)
    key_manager = Fog::KeyManager::OpenStack.new(@connection_params)
    response = key_manager.list_containers(limit: 10000000)
    container_list = (response.data[:body])['containers']
    if !container_list.nil?
      container_list.each do |container|
        if container['name'] == container_name
          return container['container_ref']
        end
      end
    else
      return false
    end
      return false
  end

  def cleanup_all(certificate,private_key,passphrase,intermediates)
    delete(certificate.split('/').last)
    delete(private_key.split('/').last)
    delete(intermediates.split('/').last)
    delete(passphrase.split('/').last)
  end


end
