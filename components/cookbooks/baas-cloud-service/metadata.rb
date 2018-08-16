name             "Baas-cloud-service"
description      "Baas Cloud Service"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'repository_url',
  :description => "Repository URL",
  :required => "required",
  :format => {
    :category => '1.Global',
    :order => 1,
    :help => 'Repository URL for baas driver'
  }

  attribute 'driver_version',
  :description => "Driver Version",
  :required => "required",
  :format => {
    :category => '1.Global',
    :order => 1,
    :help => 'Repository URL for baas driver'
  }
  