name             "Keywhiz-cloud-service"
description      "Keywhiz Cloud Service"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.catalog', 'catalog', 'mgmt.manifest', 'manifest', 'bom', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'host',
  :description => "Keywhiz service host",
  :required => "required",
  :format => {
    :category => '1.Global',
    :order => 1,
    :help => 'Keywhiz service host'
  }

attribute 'port',
  :description => "Keywhiz service port",
  :required => "required",
  :format => {
    :category => '1.Global',
    :order => 2,
    :help => 'Keywhiz service port'
  }

attribute 'client_cert',
  :description => "Client Cert",
  :data_type => "text",
  :encrypted => true,
  :required => "required",
  :format => {
    :category => '1.Global',
    :order => 3,
    :help => 'Combined client cert (in pem format including key, cert and ca cert) provided by keywhiz server for mutual TLS auth.'
  }

attribute 'keysync_download_url',
  :description => "Keysync download url",
  :required => "required",
  :format => {
    :category => '1.Global',
    :order => 4,
    :help => 'Download url to the keysync binary tar.gz file'
  }

attribute 'sync_cert_params',
  :description => "Keywhiz cert attributes",
  :data_type => 'hash',
  :format => {
    :category => '1.Global',
    :data_type => 'hash',
    :order => 5,
    :help => 'Attributes required for configuring keysync-cert'
  }

