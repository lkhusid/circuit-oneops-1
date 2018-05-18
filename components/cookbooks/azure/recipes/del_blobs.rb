os_disk_blobname = (node['vhd_uri'].split('/').last).chomp('.vhd')
OOLog.info("Deleting os_disk : #{os_disk_blobname}")

rg_manager = AzureBase::ResourceGroupManager.new(node)
storage_account_name = node['storage_account']
creds = rg_manager.creds
creds[:azure_storage_access_key] = Fog::Storage::AzureRM.new(rg_manager.creds).get_storage_access_keys(rg_manager.rg_name, storage_account_name)[1].value
creds[:azure_storage_account_name] = storage_account_name

storage_service = Fog::Storage::AzureRM.new(creds)
storage_service.delete_disk(os_disk_blobname, options = {})
