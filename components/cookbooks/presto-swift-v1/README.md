presto-swift Cookbook (V1 Build)
================================
This cookbook creates a Presto Swift Connector.

Requirements
------------
Platform:

* CentOS and Red Hat

Dependencies:

* Oracle JDK 1.8
* Presto

Attributes
----------
* `connection_name` - The name of the connection, default swift
* `connection_metastore_url` - The metastore thrift url for Swift, default thrift://HOST_NAME:9083
* `connector_config` - Additional properties to set in the connector configuration

Attributes to be removed once Hadoop client component is available
----------


License and Authors
-------------------
Authors:
Chris Undernehr
Daniel Montroy
