require 'simplecov'
require 'webmock/rspec'


require File.expand_path('../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../libraries/secret_manager', __FILE__)

describe 'SecretManager' do

  it 'should initialize connection params' do
    secret_manager = SecretManager.new("openstack_auth_url", "openstack_username", "openstack_api_key", "openstack_tenant" )
    expect(secret_manager.nil?).to be false

  end

  it 'should initialize connection params' do
    expect{SecretManager.new("openstack_auth_url", "openstack_username", "openstack_api_key", nil )}.to raise_error(ArgumentError)

  end

  it 'should create secret' do
    secret_manager = SecretManager.new("openstack_auth_url", "openstack_username", "openstack_api_key", "openstack_tenant" )
    secret = {
        "name" =>             "secret_name",
        "payload" =>  "secret_content",
        "payload_content_type" =>     "payload_content_type",
        "algorithm" =>        "algorithm",
        "mode" =>             "mode",
        "bit_len" =>        "256"
    }

    secret_manager.create(secret)

  end
end