# Cloud RDBMS backup recipe
#
#

if ! File.file?('/usr/local/bin/objectstore')
  Chef::Log.info("CloudRDBMS exit list_backups because objectstore not installed: /usr/local/bin/objectstore")
  return
end

backup_id = CloudrdbmsArtifact::get_backup_id_from_node(node)
clustername = node['cloudrdbms']['clustername']
runonenv = node['cloudrdbms']['runOnEnv']

Chef::Log.info("CloudRDBMS started to list available backups with backup_id=#{backup_id}")
%x( sudo /app/backup_n_restore.sh list_backups -i "#{backup_id}" -o "/tmp/sorted_backups" >/tmp/list_backups.log 2>&1 )

if $?.exitstatus != 0
  Chef::Log.info("#{`sudo cat /tmp/list_backups.log`}")
  raise RuntimeError, "CloudRDBMS failed to list all available backups in objectstore"
else
  backup_list = "#{`sudo cat /tmp/sorted_backups`}"

  if backup_list.length > 0
    list_results =  backup_list
  else
    list_results =  "Sorry! There are no backups available for this database."
  end

  Chef::Log.info("CloudRDBMS available backups in reverse chronological order: #{list_results}")
end

