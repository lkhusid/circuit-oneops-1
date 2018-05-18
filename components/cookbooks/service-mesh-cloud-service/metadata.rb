name             "Service-mesh-cloud-service"
description      "Service Mesh Cloud Service"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'mesh_artifact_url',
  :description => "Mesh Artifact URL",
  :required => "required",
  :format => {
    :category => '1.Global',
    :order => 1,
    :help => 'URL for service mesh artifact'
  }

attribute 'sr_url_prod',
  :description => 'Service Registry Production URL',
  :required => 'optional',
  :format => {
    :category => '1.Global',
    :order => 2,
    :help => 'Service Registry prod URL for service-mesh to reach out to for service discovery'
  }

attribute 'sr_url_nonprod',
  :description => 'Service Registry Non-production URL',
  :required => 'optional',
  :format => {
    :category => '1.Global',
    :order => 3,
    :help => 'Service Registry non-prod URL for service-mesh to reach out to for service discovery'
  }
