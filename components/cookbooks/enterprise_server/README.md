# Enterprise Server Cookbook #
Enterprise server is a cookbook designed to install TomEE/ Enterprise Server.
A Java EE 7 server with Hibernate, Hibernate validation, Hazelcast, and Common
core components such as configuration, logging and SOA-RI client.

e.g.
### Requirements
- `java` - required to run the application server
- `ssl` - required to enable HTTPS traffic

## Attributes

Below are a list of attributes which effect different parts of the installation and maintenance process.


#### Installation<br>

|Key|Type|Description|Default|
|---|---|---|---|
|['entsrv']['install_root_dir']|String|Absolute system path in which the binary will be installed.|/opt|
|['entsrv']['instal_repo']|String|- Release Repository<br>- SNAPSHOT Repository - Used for testing|Release Repository|
|['entsrv']['instal_version']|String|version to install|LATEST|

#Usage

### enterprise-server::default
Include `enterprise-server` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[enterprise-server]"
  ]
}
```

### License and Authors
(c) Copyright OneOps, All rights reserved.

### Authors:
OneOps Team
