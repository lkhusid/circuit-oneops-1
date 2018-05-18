def exit_with_error(msg)
  puts "***FAULT:FATAL=#{msg}"
  Chef::Application.fatal!(msg)
end

def get_azure_storage_service(creds, resource_group, storage_account_name)
  creds[:azure_storage_access_key] = Fog::Storage::AzureRM.new(creds).get_storage_access_keys(resource_group, storage_account_name)[1].value
  creds[:azure_storage_account_name] = storage_account_name
  return Fog::Storage::AzureRM.new(creds)
end

#TO-DO combine this method with the same method from Volume::Storage class
def get_compute(storage_provider, compute_service, instance_id, resource_group_name = nil)
  compute = nil
  begin
    if storage_provider =~ /azure/
      compute = compute_service.servers(:resource_group => resource_group_name).get(resource_group_name, instance_id)
    else
      compute = compute_service.servers.get(instance_id)
    end
  rescue => ex
    if ex.respond_to?('message')
      exit_with_error("Error in get_compute: #{ex.message}") unless ex.message =~ /was not found/
    else
      exit_with_error("Unspecified error in get_compute")
    end
  end
  compute
end
