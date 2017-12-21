<iframe src="../walmartlabs.Cloudrdbms/nav.html" height="50px" width="100%" marginwidth="0" marginheight="0" align="top" scrolling="No" frameborder="0" hspace="0" vspace="0"></iframe>

[comment]: # (notice that some lines end with 2 SPACE characters, this creates a NEWLINE in this markdown format, so do not remove those 2 trailing spaces)
[comment]: # (the lines with *** will create a horizontal rule in the page once its rendered by a browser)

##CloudRDBMS Component##

###Monitors###

1) **CPU/Memory/Network**: there are oneops monitors in the *compute* component  
2) **Disk Space**: there are oneops monitors in the *volume-app* component  
3) monitors in the *cloudrdbms* component:  
#1: **ClusterLogErrorCount**: it monitors the database (MariaDB/Galera) log file `/var/lib/mysql/mysqlcloudrdbms.log`  
#2: **DBalive**: it runs a query on the DB, to verify if DB is alive and processing data  
#3: **DBmetrics**: DB performance: selects/second; updates/second; inserts/second; deletes/second  
#4: **DBprocess**: verify that the database Linux process is running. Linux process name is `mysqld`  
#5: **JavaAgentLog**: log files for the Java program called &quot;Agent&quot;. File `/app/db/current/bin/cloudrdbms.log`  
#6: **JavaAgentprocess**: verify that the Java &quot;Agent&quot; Linux process is running. Linux process name is `MySQLAgent`  
#7: **ClusterLog2ErrorCount**: it monitors the INNODB backup log file `/var/lib/mysql/innobackup.backup.log`  
#8: **ClusterMembership**: check if the cluster has a valid primary component  
#9: **DRReplicationLink**: for DR async replication: it checks the health of the replication.  
this does not monitor the Galera cluster, this is for DR, replication from one cluster to another.  
#10: **DBbackup**: for backups: it checks the health of the backup process.  
checks to ensure that a backup has been taken in the last 36 hours.  

***

###Operations###
<img src="../walmartlabs.Cloudrdbms/crdbms_actions.png" width="800">

  * backup - backup mysql database by checking just **ONE** component instance, and clicking backup action
  * restore - Restore a backup from objectstore by checking **ALL** component instances, and clicking restore action
  * stop - stop the mysql database - see our [FAQ page](https://confluence.walmart.com/x/Ck-BCQ "click here") for HOW TO STOP the whole cluster
  * restart - stop and then start the mysql database
  * start - start the mysql database - see our [FAQ page](https://confluence.walmart.com/x/Ck-BCQ "click here") for HOW TO START the whole cluster
  * status - show whether mysql is running or not
  * replace - (operation not supported)
  * undo replace - (operation not supported)

***

####Restore####
<img src="../walmartlabs.Cloudrdbms/crdbms_restore_action.png" width="800">

Restore action enables restoring the database to any specific backup (be it incremental or full backup) that has been previously taken from any cluster (provided that they have the same objectstore configuration).  
For this purpose, the restore action requires customers to specify the cluster that will be restored and the restore time.  
The concatenation of organization, assembly, environment, and platform uniquely identifies a cluster.  
The restore time is in the format of `YYYY-MM-DD-HH24-MM-SS` (e.g., `2016-04-13-21-00-00`).  
Currently, this action will restore to the latest backup that is taken before the given restore time. For example, if a cluster has taken backups at 2016-04-13-21-00-00, 2016-04-14-21-00-00, and 2016-04-15-21-00-00. Any given time in the range [2016-04-13-21-00-00, 2016-04-14-21-00-00) (i.e., from 2016-04-13-21-00-00 inclusively to 2016-04-14-21-00-00 exclusively) will make the restore action to restore the database to the backup corresponding to time 2016-04-13-21-00-00.

* **organization**: the oneops organization name of the cloudrdbms cluster to be restored from
* **assembly**: the oneops assembly name of the cloudrdbms cluster to be restored from
* **environment**: the environment name of the cloudrdbms cluster to be restored from
* **platform**: the platform name of the cloudrdbms cluster to be restored from
* **time**: the restore time (UTC timezone)
