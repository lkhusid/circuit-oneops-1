# Cloud RDBMS backup recipe
#
#
if ! File.file?('/usr/local/bin/objectstore')
     Chef::Log.info("CloudRDBMS exit backup because objectstore not installed: /usr/local/bin/objectstore")
     return
end

#this recipe takes an argument, however this argument is not exposed to users
#this way, we can use chef-solo to call the recipe with parameters.
if node.workorder.arglist == nil || node.workorder.arglist.empty?
  backup_type = "full"
else
  args=::JSON.parse(node.workorder.arglist)
  backup_type=args["backup_type"]
  backup_type = "full" if backup_type == nil || backup_type == ""
  backup_type.strip!
end
if backup_type != "full" && backup_type != "incremental"
  raise RuntimeError, "CloudRDBMS unsupported backup type, must be either full or incremental"
end  

current_ip=`/sbin/ifconfig | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1 | grep -v 10.0. | head -1`
current_ip.strip!
Chef::Log.info("CloudRDBMS starts #{backup_type} backup procedure from #{current_ip}")

### Get the backup id of the current cluster
backup_id = CloudrdbmsArtifact::get_backup_id_from_node(node)
clustername = node['cloudrdbms']['clustername']
runonenv = node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile].downcase

Chef::Log.info("CloudRDBMS backup configs: backup_type=#{backup_type}, backup_id=#{backup_id}")

mysql_status_results = `service mysql status 2>&1`
mysql_status_results.strip!
if ! (mysql_status_results =~ /SUCCESS/)
  raise RuntimeError, "server #{current_ip} is not running, abort backup operations"
end

Chef::Log.info("CloudRDBMS backup starts to generate and upload a database snapshot to objectstore")
%x( sudo /app/backup_n_restore.sh "#{backup_type}" -e "#{runonenv}" -c "#{clustername}" -i "#{backup_id}" -r "yes" >/tmp/backup.log 2>&1 )
if $?.exitstatus != 0
  Chef::Log.info("#{`sudo cat /tmp/backup.log`}")
  raise RuntimeError, "CloudRDBMS node #{current_ip} failed to generate and then upload a snapshot of the database to objectstore"
else
  Chef::Log.info("CloudRDBMS node #{current_ip} successfully generated and then uploaded a snapshot of the database to objectstore")
end
