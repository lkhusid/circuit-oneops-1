<iframe src="../walmartlabs.Cloudrdbms/nav.html" height="50px" width="100%" marginwidth="0" marginheight="0" align="top" scrolling="No" frameborder="0" hspace="0" vspace="0"></iframe>

[comment]: # (notice that some lines end with 2 SPACE characters, this creates a NEWLINE in this markdown format, so do not remove those 2 trailing spaces)
[comment]: # (the lines with *** will create a horizontal rule in the page once its rendered by a browser)

#Compute Component#

##Operations

<img src="../walmartlabs.Cloudrdbms/compute.png" width="600">

1. Before POWERCYCLE / REBOOT / REPLACE: stop the database on that specific VM:
    * select the **cloudrdbms** component instance that corresponds to the **compute** instance that you would like to POWERCYCLE/REBOOT/REPLACE
    * click STOP (see the CloudRDBMS Component tab for more info)
1. after you have STOPped the database on that VM: now you can proceed with the **compute** POWERCYCLE / REBOOT / REPLACE
1. POWERCYCLE / REBOOT / REPLACE: do not do this action on all **compute** instances at the same time: do it on 1 instance at a time (remember to STOP the DB as explained above)
