# CentrifyDC Service (Beta 1)
This service is used to manage connectivity to an instance of Centrify DirectControl.  This service contains the credentials used to access the directory along with the relevant LDAP information.

## How to Use
The service has the following attributes that need to be configured:

* **centrify_url** - This is the link to where the Centrify RPM can be downloaded.
* **centrify_zone** - This is the default Centrify zone name to use.  it can be overridden by the **centrify** component.
* **zone_user** - The username to use when configuring the zone.
* **zone_pwd** - The password to use when configuring the zone.
* **ldap_container** - The LDAP container where the server objects will be created.
* **domain_name** - The domain name corresponding to the LDAP directory.
* **user_dir_parent** - The directory location where user directories will be created.  This directory will be created on computes that are joined to a zone.  (Optional)

Once the CentrifyDC service is added to a cloud, then assemblies can be created with the **centrify** component instantiated inside them.
