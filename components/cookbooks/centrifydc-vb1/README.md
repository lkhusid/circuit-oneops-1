CentrifyDC Service (Beta 1)
===========================
This service represents Centrify DirectControl.  It contains the enterprise
wide attributes needed to configure it.

Requirements
------------
This service requires CentrifyDC to have already been installed.

Usage
-----
To use the service, add it to your cloud, and configure the credentials,
domain, and LDAP container.

Attributes
----------
* **centrify_url** - The URL to use to download the Centrify RPM.
* **centrify_zone** - The default zone name to use when joining to Centrify.
* **ldap_container** - The LDAP container to create the server objects in.
* **domain_name** - The domain to join.
* **user_dir_parent** - The parent directory to create that will contain user home directories
