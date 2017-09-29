require 'simplecov'
require 'webmock/rspec'


require File.expand_path('../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../../libraries/loadbalancer_manager', __FILE__)
require File.expand_path('../../../libraries/health_monitor_manager', __FILE__)

require File.expand_path('../../../libraries/network_manager', __FILE__)
require File.expand_path('../manager_spec_helper',__FILE__)

describe 'LoadbalancerManager' do

  let(:lb) {Helpers::Helper.new}
  let(:fake_class) {Helpers::Fake_class.new()}

  include Helpers
  subject(:tenant) { TenantModel.new('http://10.0.2.15:5000', 'tenant_name', 'username', 'password')}

  it 'validates contructor' do
    lb_manager = LoadbalancerManager.new(tenant)
    expect(lb_manager.nil?).to be false
  end

context 'create_loadbalancer' do

  it 'successfully create new lb' do
    stub_const("LoadbalancerManager::Chef::Log",fake_class)
    token_helper
    parent_helper_method
    lb_name_list_create_success_helper_method
    lb_manager = LoadbalancerManager.new(tenant)
    lb_obj= lb.get_lb()
    expect(lb_manager.create_loadbalancer(lb_obj)).to be =~ /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  end

  it 'Raise exception if lb with the name exists already' do
    stub_const("LoadbalancerManager::Chef::Log",fake_class)
    token_helper
    parent_helper_method
    lb_name_list_create_fail_helper_method
    lb_manager = LoadbalancerManager.new(tenant)
    lb_obj= lb.get_lb()
    expect{lb_manager.create_loadbalancer(lb_obj)}.to raise_error("Cannot create Loadbalancer unit-test-lb-http already exist.")

  end

end
  context 'get_loadbalancer' do

    it 'loadbalancer_id cannot be nil' do
      token_helper
      lb_manager = LoadbalancerManager.new(tenant)
      lb_obj= lb.get_lb()
      expect{lb_manager.get_loadbalancer(lb_obj.id)}.to raise_error(ArgumentError)
    end

    it 'loadbalancer_id cannot be empty' do
      token_helper
      lb_manager = LoadbalancerManager.new(tenant)
      lb_obj= lb.get_lb()
      expect{lb_manager.get_loadbalancer("")}.to raise_error(ArgumentError)
    end

    it 'loadbalancer_id is valid name and found' do
      token_helper
      lb_name_list_create_fail_helper_method
      parent_helper_method
      lb_manager = LoadbalancerManager.new(tenant)
      expect{lb_manager.get_loadbalancer("unit-test-lb-http")}.not_to raise_error
    end

    it 'loadbalancer_id is guid and found' do
      token_helper
      parent_helper_method
      lb_manager = LoadbalancerManager.new(tenant)
      expect{lb_manager.get_loadbalancer("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")}.not_to raise_error
    end

    it 'loadbalancer name not found' do
      token_helper
      parent_helper_method
      lb_manager = LoadbalancerManager.new(tenant)
      expect{lb_manager.get_loadbalancer("xvcvcvc")}.to raise_error
    end

    it 'loadbalancer id not found' do
      token_helper
      parent_helper_method
      lb_manager = LoadbalancerManager.new(tenant)
      expect{lb_manager.get_loadbalancer("ee027e73-231b-5g5g-4567-41c5392345ba")}.to raise_error
    end




  end

  context 'delete_loadbalancer' do
    it 'loadbalancer_id cannot be nil' do
      token_helper
      lb_manager = LoadbalancerManager.new(tenant)
      lb_obj= lb.get_lb()
      expect{lb_manager.delete_loadbalancer(lb_obj.id)}.to raise_error(ArgumentError)
    end

    it 'loadbalancer_id is guid, raise error' do
      token_helper
      parent_helper_method

      lb_manager = LoadbalancerManager.new(tenant)
      expect{lb_manager.delete_loadbalancer("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")}.to raise_error(RuntimeError)
    end

    it 'loadbalancer_id is valid lb name, deletes lb succesfully' do
      token_helper
      parent_helper_method

      lb_name_list_create_fail_helper_method

      lb_manager = LoadbalancerManager.new(tenant)
      expect(lb_manager.delete_loadbalancer("unit-test-lb-http")).to be true
    end

    it 'loadbalancer_id is invalid lb name, raise error' do
      token_helper
      parent_helper_method

      lb_name_list_create_fail_helper_method

      lb_manager = LoadbalancerManager.new(tenant)

      expect{lb_manager.delete_loadbalancer("unit-test")}.to raise_error
    end


  end

  end
