presto-mysql Cookbook (V2 Build)
================================
This cookbook creates a Presto MySQL Connector.

See https://prestodb.io/docs/current/connector/mysql.html for more details about the Presto MySQL Connector

Requirements
------------
Platform:

* CentOS and Red Hat

Dependencies:

* Oracle JDK 1.8
* Presto


Attributes
----------
* `connection_name` - The name of the connection, default mysql
* `connection_url` - The JDBC url for MySQL, default jdbc:mysql://example.net:3306.
* `connection_user` - The user id used to access MySQL.
* `connection_password` - The password for MySQL
* `connector_config` - Additional properties to set in the connector configuration

License and Authors
-------------------
Authors:
Chris Undernehr
Daniel Montroy
