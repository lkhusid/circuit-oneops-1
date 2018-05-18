# Checks if data symlink exists.
# If exists and points to /blockstorage (Cinder)
#   1. Copy the data from /blockstorage to /app/solrdata6/data_backup
#   2. Remove the symlink
#   3. Move the directory /app/solrdata6/data_backup to data
# If data is a symlink and points to any directory other than /blockstorage (Non-cinder)
#   1. Remove the symlink
#   2. Move the directory pointed to by the symlink to data
# If symlink doesn't exist - do nothing
parent_data_dir = node['data_dir_path']
data_dir = "#{parent_data_dir}/data"
if !File.symlink?(data_dir)
  Chef::Log.info("#{data_dir} is not a symlink. It is a directory.")
  return
else
  Chef::Log.info("data symlink exists in #{parent_data_dir}.")
  data_link_path = File.readlink(data_dir)

  # If data is in Cinder
  if node.has_key?("cinder_volume_mountpoint") && !node["cinder_volume_mountpoint"].empty? && (data_link_path == node["cinder_volume_mountpoint"])
    cinder_data = node["cinder_volume_mountpoint"]
    data_backup = "#{parent_data_dir}/data_backup"
    Chef::Log.info("#{data_dir} is a symlink and it points to Cinder mount point - #{node["cinder_volume_mountpoint"]}.")
    Chef::Log.info("We will move Solr data from blockstorage to ephemeral and convert the data symlink to an actual directory")
    bash 'copy_blockstorage_data' do
      code <<-EOH
      sudo mkdir -p #{data_backup}
      sudo chown #{node['solr']['user']}:#{node['solr']['user']} #{data_backup}
      sudo cp -r #{cinder_data}/* #{data_backup}
      sudo rm #{data_dir}
      sudo mkdir -p #{data_dir}
      sudo chown #{node['solr']['user']}:#{node['solr']['user']} #{data_dir}
      sudo mv #{data_backup}/* #{data_dir}
      sudo rm -rf #{data_backup}
      EOH
    end
  else
    Chef::Log.info("#{data_dir} is a symlink and it points to #{data_link_path}")
    bash 'move_data' do
      code <<-EOH
      sudo rm #{data_dir}
      sudo mkdir -p #{data_dir}
      sudo chown #{node['solr']['user']}:#{node['solr']['user']} #{data_dir}
      sudo mv #{data_link_path}/* #{data_dir}
      EOH
    end
  end
end