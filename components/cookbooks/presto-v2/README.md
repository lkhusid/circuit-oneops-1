presto Cookbook (V2 Build)
==========================
This cookbook creates Presto clusters.  See https://prestodb.io/ for more details about Presto

Requirements
------------
Platform:

* CentOS and Red Hat

Dependencies:

* Oracle JDK 1.8


Attributes
----------
* `version` - Version number of Presto to install.  For example: 0.148.SNAPSHOT-1.x86_64
* `http_port` - HTTP port to use for all communication.  default `8080`
* `data_directory_dir` - Location for metadata and temporary data, default `/mnt/presto/data`.
* `query_max_memory` - The maximum amount of distributed memory that a query may use, default `50GB`.
* `query_max_memory_per_node` - The maximum amount of memory that a query may use on any one machine, default `1GB`.
* `ganglia_servers` - The ganglia servers to point metrics to. Format HOST:PORT
* `jmx_mbeans` - A comma separated list of Managed Beans (MBean). It specifies which MBeans will be sampled and stored in memory every, default `java.lang:type=Runtime,com.facebook.presto.execution.scheduler:name=NodeScheduler`.
* `jmx_dump_period` - Interval that data is polled, default `10s`.
* `jmx_max_entries` - The size of the history for the JMX entries, default `86400`.
* `log_level` - The log level for Presto, default `INFO`.
* `presto_mem` - Heap size for Presto.  This is the Xmx setting for the JVM, default `51G`.
* `presto_thread_stack` - Thread stack size for Presto.  This is the Xss setting for the JVM, default `768k`.
License and Authors
-------------------
Authors:
Chris Undernehr
Daniel Montroy
