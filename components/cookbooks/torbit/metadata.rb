name             "Torbit"
description      "Torbit cloud service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

  
attribute 'user_name',
  :description => "User Name",
  :required => "required",
  :default => "",
  :format => {
    :help => 'User Name',
    :category => '1.Global',
    :order => 1
  }

attribute 'auth_key',
  :description => "Auth Key",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Auth Key',
    :category => '1.Global',
    :order => 2
  }

attribute 'group_id',
  :description => "Group Id",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Group ID',
    :category => '1.Global',
    :order => 3
  }

attribute 'endpoint',
  :description => "API Endpoint",
  :required => "required",
  :default => "",
  :format => {
    :help => 'API Endpoint URL',
    :category => '1.Global',
    :order => 4
  }

attribute 'gslb_base_domain',
  :description => "GSLB Base Domain",
  :required => "required",
  :default => '',
  :format => { 
    :category => '1.Global', 
    :order => 5, 
    :help => 'GSLB Base Domain'
  }


attribute 'client_cert',
  :description => "Client Cert",
  :data_type => "text",
  :encrypted => true,
  :format => {
    :category => '1.Global',
    :order => 6,
    :help => 'Client cert for mutual TLS auth'
  }
