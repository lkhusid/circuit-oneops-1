require 'simplecov'
require 'webmock/rspec'


require File.expand_path('../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../../libraries/loadbalancer_manager', __FILE__)
require File.expand_path('../../../libraries/health_monitor_manager', __FILE__)
require File.expand_path('../../../libraries/pool_manager', __FILE__)
require File.expand_path('../../../libraries/member_manager', __FILE__)


require File.expand_path('../../../libraries/network_manager', __FILE__)
require File.expand_path('../manager_spec_helper',__FILE__)

describe 'PoolManager' do
  let(:lb) {Helpers::Helper.new}
  let(:fake_class) {Helpers::Fake_class.new()}
  include Helpers
  subject(:tenant) { TenantModel.new('http://10.0.2.15:5000', 'tenant_name', 'username', 'password')}

  it 'should validate poolmanager constructor' do

    poolmanager = PoolManager.new(tenant)
    expect(poolmanager.nil?).to be false

  end

  context 'validate update_pool' do
    it 'updates pool successfully with right parameters' do
      token_helper
      parent_helper_method
      stub_const("PoolDao::Chef::Log",fake_class)


      pool_manager = PoolManager.new(tenant)
      lb_manager = LoadbalancerManager.new(tenant)
      lb_existing = lb_manager.get_loadbalancer("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")
      expect {pool_manager.update_pool("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4","ad1236b9-b490-44c9-bfe8-48beb86e3130", "8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", lb_existing.listeners[0].pool)}.not_to raise_error
    end

  end


end