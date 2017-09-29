
def exit_with_error(msg)
  puts "***FAULT:FATAL=#{msg}"
  Chef::Application.fatal!(msg)
end

def execute_command(command)
  output = `#{command} 2>&1`
  if $?.success?
    Chef::Log.info("#{command} got successful.. #{output.gsub(/\n+/, '.')}")
  else
    exit_with_error "#{command} got failed.. #{output.gsub(/\n+/, '.')}"
  end
end

def get_storage()

  storage = nil
  device_map = []
  storage_name = nil

  #localizing the new algorithm to windows VMs only
  #to-do test with Linux
  if node.platform !~ /windows/
    Chef::Log.info("Matching storage for Linux VM")
    node.workorder.payLoad[:DependsOn].each do |dep|
      if dep[:ciClassName] =~ /Storage/
        storage = dep
        device_map = storage[:ciAttributes][:device_map].split(" ")
        break
      end
    end
  else
    Chef::Log.info("Matching storage for Windows VM")
    #For windows VMs - continue and try to match volume and storage components
    if node[:workorder][:rfcCi][:ciAttributes].has_key?(:based_on_storage)
      storage_name = "#{node[:workorder][:rfcCi][:ciAttributes][:based_on_storage]}-#{node[:workorder][:cloud][:ciId]}"
    end

    #Get all storages from DependsOn
    storages_all = []
    storages_all = node[:workorder][:payLoad][:DependsOn].select { |st| (st['ciClassName'] =~ /Storage/ )}

    #Get deduplicated array of storages
    storages = []
    if storages_all.size > 0
      storages_all.each {|i| storages.push({:storage=>i[:ciName],:device_map=>i[:ciAttributes][:device_map]}) }
      storages = storages.uniq
    end

    #Storages found, trying to determine which one to use
    if storages.size > 0

      #1 - Searching for storage component with the name matching based_on_storage attribute
      if !storage_name.nil?
        storage = storages.select { |st| (st[:storage] =~ /#{storage_name}/ )}

        if storage.size > 1
          exit_with_error ("Matching using based_on_storage - Incorrect amount of matching storage components: #{storage.size}")
        else
          storage = storage.first
          Chef::Log.info("Storage matched by using Based_on_Storage attribute")
        end
      end

      #2 - Searching for storage component with the name matching this volume component name - storageABC = volumeABC
      if storage.nil?
        storage = storages.select { |st| (st[:storage].sub('storage','') == node[:workorder][:rfcCi][:ciName].sub('volume','') )}
        if storage.size > 1
          exit_with_error ("Matching by component names - Incorrect amount of matching storage components: #{storage.size}")
        else
          storage = storage.first
          Chef::Log.info("Storage matched by using volume-storage component names")
        end
      end

      #3 - did not find matching storage so picking the first one - old behavior
      if storage.nil?
        storage = storages.first
      end

    end #if storages.size > 0

    if !storage.nil? && storage.has_key?(:device_map)
      device_map = storage[:device_map].split(' ')
    end

  end #if node.platform !~ /windows/ else

  return storage, device_map
end
