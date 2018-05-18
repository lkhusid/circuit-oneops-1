name             'Hadoop-yarn-cluster-v1'
maintainer       '@WalmartLabs'
maintainer_email 'dmoon@walmartlabs.com'
description      'Hadoop YARN Cluster (v1 build)'
long_description 'Hadoop YARN Cluster (v1 build)'
version          '1.0.0'

grouping 'default',
    :access => "global",
    :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]
