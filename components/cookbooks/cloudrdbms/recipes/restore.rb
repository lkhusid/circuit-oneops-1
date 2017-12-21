# Cloud RDBMS restore recipe
# Assume that every node is healthy and already joined the primary cluster.
# This recipe is destructive, all existing data will be removed
#
require 'json'

if ! File.file?('/usr/local/bin/objectstore')
  Chef::Log.info("CloudRDBMS exit restore because objectstore not installed: /usr/local/bin/objectstore")
  return
end

current_node=`hostname -f`
current_node.strip!
Chef::Log.info("CloudRDBMS starts restore procedure at #{current_node}")

#retrieve the parameter values entered by customers
args=::JSON.parse(node.workorder.arglist)
#compute the backup_id, if any of the organization, assembly, environment, or platform argument is missing,
#use the corresponding value of the current cluster
backup_id = CloudrdbmsArtifact::get_backup_id_with_defaults(node, args["organization"], args["assembly"], args["environment"], args["platform"])
Chef::Log.info("CloudRDBMS restore configs: backup_id=#{backup_id}")
#if the time value is not set, it is default to the current time
restoreTime=args["time"]
if restoreTime.to_s.strip.length == 0
  restoreTime=`date -u "+%Y_%m_%d-%H_%M_%S"`
else
  if restoreTime  !~ /^[0-9]{4}.[0-9]{2}.[0-9]{2}.[0-9]{2}.[0-9]{2}.[0-9]{2}$/
    raise RuntimeError, "CloudRDBMS invalid restore time format, should be like 2016_09_00-01_04_00"
  end
end

#get the state uuid before restore
txid = CloudrdbmsArtifact::getGrastateLocally()

#shutdown the server if it is running
Chef::Log.info("CloudRDBMS current node #{current_node} is stopping")
%x( sudo service mysql stop )
#if calling the stop recipe, the rest of the recipe code needs to be wrapped in a ruby_block
#include_recipe "cloudrdbms::stop"
Chef::Log.info("CloudRDBMS current node #{current_node} stopped")

Chef::Log.info("CloudRDBMS current node #{current_node} is clearing up data and binlog directories")
%x( sudo /app/backup_n_restore.sh rm_db )
Chef::Log.info("CloudRDBMS current node #{current_node} cleared up data and binlog directories")

#we choose the node with the least ip to be the restore node instead of the bootstrapping node which may be gone
#use the bootstrap node, you must make it valid and consistent always
restore_node =`sudo cat /app/listofIP.log | sort | head -1`
restore_node.strip!
Chef::Log.info("CloudRDBMS chose #{restore_node} as the restore node")

#or we can just use the bootstrap node as the restore node
#restore_node=`sudo cat /app/bootstrap_node.txt`
#restore_node.strip!
#if restore_node.include? "ERROR"
#  Chef::Log.error("CloudRDBMS the bootstrapping server that we use it as the restore server as well is invalid")
#  raise RuntimeError, "the bootstrapping server that we use it as the restore server as well is invalid"
#end

#if this node is not the chosen one to restore to the entire cluster, it needs to check if the chosen one is up with a new cluster state uuid
#otherwise, this node needs to restore data from objectstore and bootstrap the cluster
if current_node.eql?(restore_node)
  Chef::Log.info("CloudRDBMS starts to restore a database from objectstore to server #{current_node}")
  Chef::Log.info("yes | sudo /app/backup_n_restore.sh restore -r yes -i #{backup_id} -t #{restoreTime}")
  %x( yes | sudo /app/backup_n_restore.sh "restore" -r "yes" -i "#{backup_id}" -t "#{restoreTime}" >/tmp/restore.log 2>&1 )
  if  $?.exitstatus != 0
    Chef::Log.info("#{`sudo cat /tmp/restore.log`}")
    raise RuntimeError, "CloudRDBMS failed to restore a database from objectstore to server #{current_node}"
  else
    Chef::Log.info("CloudRDBMS successfully restored a database from objectstore to server #{current_node}")
  end
else
  #the cluster_state_uuid changed after restore
  txid_new = nil
  begin
    sleep(30)
    txid_new = CloudrdbmsArtifact::getGrastate("#{restore_node}")
    Chef::Log.info("CloudRDBMS node #{current_node} detected that the restore node #{restore_node} has not bootstrapped yet")
  end while (txid_new == nil) || (txid && txid_new[":uuid"] == txid[":uuid"])

  Chef::Log.info("CloudRDBMS start to join server #{current_node} to the restore node #{restore_node} into primary component")
  include_recipe "cloudrdbms::start"

  #restore database permissions
  ruby_block 'restore_permissions' do
    block do
      Chef::Log.info("CloudRDBMS start to restore access permission to data and log bin directories")
      %x( sudo /app/backup_n_restore.sh "restore_permissions" > /tmp/restore_permissions.log 2>&1 )
      Chef::Log.info("#{`sudo cat /tmp/restore_permissions.log`}")
    end
  end

  #if we need to start the cluster without using the start recipe, we can start the cluster by letting other servers join the restore server
  #Chef::Log.info("CloudRDBMS node #{current_node} detected that the restore node #{restore_node} has already bootstrapped! now is joining it into primary component")
  #%x( service mysql start )
  #  if  $?.exitstatus != 0
  #    Chef::Log.error("CloudRDBMS node #{current_node} failed to join #{restore_node}")
  #    raise RuntimeError, "CloudRDBMS node #{current_node} failed to join #{restore_node}"
  #  else
  #    Chef::Log.info("CloudRDBMS node #{current_node} successfully restored the latest backup from objectstore")
  #  end
  #end
end
