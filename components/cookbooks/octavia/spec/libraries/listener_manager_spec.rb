require 'simplecov'
require 'webmock/rspec'


require File.expand_path('../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../../libraries/loadbalancer_manager', __FILE__)
require File.expand_path('../../../libraries/health_monitor_manager', __FILE__)
require File.expand_path('../../../libraries/listener_manager', __FILE__)


require File.expand_path('../../../libraries/network_manager', __FILE__)
require File.expand_path('../manager_spec_helper',__FILE__)

describe 'ListenerManager' do

  let(:lb) {Helpers::Helper.new}
  include Helpers

  subject(:tenant) { TenantModel.new('http://10.0.2.15:5000', 'tenant_name', 'username', 'password')}

  it 'should test validate the contructor' do
    listenerManager = ListenerManager.new(tenant)
    expect(listenerManager.nil?).to be false
  end

  it 'add_listener with right parameters' do

    token_helper
    parent_helper_method
    listenerManager = ListenerManager.new(tenant)
    lb_obj= lb.get_lb()
    expect{listenerManager.add_listener("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", lb_obj.listeners[0])}.not_to raise_error

  end

  it 'delete_listener with right parameters' do

    token_helper
    parent_helper_method
    listenerManager = ListenerManager.new(tenant)

    lb_manager = LoadbalancerManager.new(tenant)
    lb_existing = lb_manager.get_loadbalancer("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")
    expect{listenerManager.delete_listener("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", lb_existing.listeners[0])}.not_to raise_error

  end

  it 'delete_listener with right parameters' do

    token_helper
    parent_helper_method
    listenerManager = ListenerManager.new(tenant)

    lb_manager = LoadbalancerManager.new(tenant)
    lb_existing = lb_manager.get_loadbalancer("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")
    expect{listenerManager.delete_listener("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", lb_existing.listeners[0])}.not_to raise_error

  end

  it 'delete_listener fails for any other error' do

    token_helper
    parent_helper_method
    listener_get_returns_403
    listenerManager = ListenerManager.new(tenant)

    lb_manager = LoadbalancerManager.new(tenant)
    lb_existing = lb_manager.get_loadbalancer("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")
    expect{listenerManager.delete_listener("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", lb_existing.listeners[0])}.to raise_error(RuntimeError)


  end

  it 'delete_listener completes succesfully without error if listener doesnt exist' do

    token_helper
    parent_helper_method

    listenerManager = ListenerManager.new(tenant)

    lb_manager = LoadbalancerManager.new(tenant)
    lb_existing = lb_manager.get_loadbalancer("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")
    expect{listenerManager.delete_listener("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", lb_existing.listeners[0])}.not_to raise_error
    expect{listenerManager.delete_listener("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", lb_existing.listeners[0])}.not_to raise_error


  end



end