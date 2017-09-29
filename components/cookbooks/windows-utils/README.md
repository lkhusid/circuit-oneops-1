# windows-utils

Accessory cookbook for Windows support in OneOps

Provides custom resources that can be used in Windows-specific recipes.

#Elevated_script resource
This resource will execute provided powershell script on the VM using LOCAL SYSTEM credentials.
It does that by creating a scheduled task and assigning it to run the provided script. 
The results of the task execution are then processed and in case of error the details are reported back to OneOps.
