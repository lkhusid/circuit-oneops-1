name             "Windows-utils"
description      "Accessory cookbook for Windows support in OneOps"
version          "0.1.0"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access   => 'global',
  :packages => [ 'base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom' ]
  