Description
===========

Installs and configures [Mcrouter](https://github.com/facebook/mcrouter)


Requirements
============

Platform: 

* CentOS 7+

Attributes
==========

* `root_dir` - root directory
* `log_dir` - log directory 
* `install_dir` - install directory
* `user` - User to run mcrouter (default mcrouter)
* `base_url` - Package base url
* `package_name` - Package name (default: mcrouter)
* `version` - Package version
* `arch` - Package architecture (default: x86_64)
* `pkg_type` - Package type (default: rpm)
* `port` - Mcrouter port number (default: 5000)
* `config-file` - Mcrouter config file path 
* `async-dir` - Mcrouter async directory spool
* `stats-root` - Mcrouter stats root directory
* `enable_asynclog` - Enable async log for failed delete stream ('true'/'false')
* `enable_flush_cmd` - Enable flush_all command ('true'/'false')
* `enable_logging_route` - Enable logging route ('true'/'false')
* `num_proxies` - Number of Mcrouter proxy threads
* `server_timeout` - Timeout in milliseconds
* `verbosity` - Verbosity level
* `additional_cli_opts` - Additional command line options
* `policy` - get/gets uses MissFailoverRoute. All other operations use one of the following policies: AllAsyncRoute (default), AllSyncRoute, AllInitialRoute, AllInitialRoute, AllFastestRoute, and AllMajorityRoute
* `route` -  Supported Routes: PoolRoute (default), HashRouteSalted : Use salted hash to server pool 
