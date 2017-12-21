#
# Cookbook Name:: cassandra
# Recipe:: config_directives
#
# Copyright 2015, @WalmartLabs.

require 'json'
cassandra_home = node.default[:cassandra_home]
cassandra_current = "#{cassandra_home}/current"

ruby_block 'update_config_directives' do
  Chef::Resource::RubyBlock.send(:include, Cassandra::Util)
  block do
    yaml = YAML::load_file("#{cassandra_current}/conf/cassandra.yaml")

    if node.workorder.has_key?("rfcCi")
      ci = node.workorder.rfcCi
    else
      ci = node.workorder.ci
    end
    cfg = JSON.parse(ci.ciAttributes.config_directives)

    cfg['cluster_name'] = node[:cluster_name] unless cfg.include?('cluster_name')
    cfg['num_tokens'] = yaml['num_tokens'] || 256 unless cfg.include?('num_tokens')
    cfg['endpoint_snitch'] = 'GossipingPropertyFileSnitch' unless cfg.include?('endpoint_snitch')
    cfg['data_file_directories'] = [node[:data_file_directories]] unless cfg.include?('data_file_directories')
    cfg['commitlog_directory'] = node[:commitlog_directory] unless cfg.include?('commitlog_directory')
    cfg['saved_caches_directory'] = node[:saved_caches_directory] unless cfg.include?('saved_caches_directory')
    cfg['listen_address'] = node[:ipaddress] unless cfg.include?('listen_address')
    cfg['rpc_address'] = '0.0.0.0' unless cfg.include?('rpc_address')
    cfg['start_rpc'] = 'true' unless cfg.include?('start_rpc')
    cfg['broadcast_rpc_address'] = node[:ipaddress] unless cfg.include?('broadcast_rpc_address')
    cfg.delete('broadcast_rpc_address') if (node[:version].to_f < 2.1)
    cfg.delete('seeds')  # <-- Provide this property to join nodes to an existing cluster.  See Cassandra::Util.find_seeds
    cfg['seed_provider'] = [{
      'class_name' => 'org.apache.cassandra.locator.SimpleSeedProvider',
      'parameters' => [  {  'seeds' => node.default[:initial_seeds].join(',')  }  ]
    }]

    if (node[:version].to_f >= 3.0)
      cfg['hints_directory'] = "#{cassandra_home}/hints" unless cfg.include?('hints_directory')
      cfg['concurrent_materialized_view_writes'] = [yaml['concurrent_writes'], yaml['concurrent_reads']].min_by {|x| x == nil ? 999 : x.to_i } unless cfg.include?('concurrent_materialized_view_writes')
    end

    cfg['authenticator'] = "AllowAllAuthenticator"
    cfg['authorizer'] = "AllowAllAuthorizer"
    if ci.ciAttributes.has_key?("auth_enabled") && ci.ciAttributes.auth_enabled.eql?("true")
    	cfg['authenticator'] = "PasswordAuthenticator"
    	cfg['authorizer'] = "CassandraAuthorizer"
    end
    yaml_file = "#{cassandra_current}/conf/cassandra.yaml"
    Chef::Application.fatal!("Can't find the YAML config file - #{yaml_file} ") if !File.exists? yaml_file
    merge_conf_directives(yaml_file, cfg)
  end
  only_if { conf_directive_supported? }
end
