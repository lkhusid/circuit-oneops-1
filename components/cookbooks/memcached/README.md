Description
===========

Installs and configures [Memcached](https://github.com/memcached/memcached)


Requirements
============

Platform: 

* CentOS 7+

Attributes
==========

* `port` - Memcached port number (default: 11211)
* `max_memory` - Max Memory for memcached
* `max_connections` - Max connections for memcached
* `user` - User to run memcached
* `log_level` - Memcached log level
* `num_threads` - Number of threads (default: 4)
* `enable_cas` - Enable cas ('true'/'false')
* `enable_error_on_memory_ex` - Enable error on memory exhaustion ('true'/'false')
* `additional_cli_opts` - Additional command line options
* `package_name` - Package name (default: 'memcached')
* `version` - version ('repo' or specific version)
* `arch` - Package architecture (default: 'x86_64')
* `pkg_type` - Package type (default: 'rpm')
