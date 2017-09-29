require 'simplecov'
require 'webmock/rspec'


require File.expand_path('../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../../libraries/loadbalancer_manager', __FILE__)
require File.expand_path('../../../libraries/health_monitor_manager', __FILE__)
require File.expand_path('../../../libraries/member_manager', __FILE__)


require File.expand_path('../../../libraries/network_manager', __FILE__)
require File.expand_path('../manager_spec_helper',__FILE__)



describe 'MemberManager' do
  let(:lb) {Helpers::Helper.new}
  let(:fake_class) {Helpers::Fake_class.new()}
  include Helpers
  subject(:tenant) { TenantModel.new('http://10.0.2.15:5000', 'tenant_name', 'username', 'password')}


  it 'should test MemberManager constructor' do
    MManager = MemberManager.new(tenant)

    expect(MManager.nil?).to be false

  end

  context 'delete_member' do


    it 'deletes member with right parameters' do
      stub_const("MemberManager::Chef::Log",fake_class)

      token_helper
      parent_helper_method

      member_manager = MemberManager.new(tenant)
      expect{member_manager.delete_member("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", "4c507d81-299e-4b1c-a153-69d2b4573277")}.not_to raise_error
    end

  end

  context'get_member' do
    it 'returns member details with valid pool_id' do

      stub_const("MemberManager::Chef::Log",fake_class)

      token_helper
      parent_helper_method

      member_manager = MemberManager.new(tenant)
      expect{member_manager.get_members("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")}.not_to raise_error


    end
  end

  context 'is member exists' do
    it 'returns true if member exists ' do

      stub_const("MemberManager::Chef::Log",fake_class)

      token_helper
      parent_helper_method

      member_manager = MemberManager.new(tenant)
      expect(member_manager.is_member_exist("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4","2620:1c0:72:8b00:f816:3eff:fe3d:8a44")).to be == true


    end
  end

  it 'returns false if member doesnt exists ' do

    stub_const("MemberManager::Chef::Log",fake_class)

    token_helper
    parent_helper_method

    member_manager = MemberManager.new(tenant)
    expect(member_manager.is_member_exist("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4","4c507d81-299e-4b1c-a153-69d2b4277")).to be == false
    #member_manager.is_member_exist("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4","4c507d81-299e-4b1c-a153-69d2b4573277")


  end

  context 'add_member' do
    it 'add member with valid pool_id' do

      stub_const("MemberManager::Chef::Log",fake_class)

      token_helper
      parent_helper_method

      member_manager = MemberManager.new(tenant)
      lb_manager = LoadbalancerManager.new(tenant)
      lb_existing = lb_manager.get_loadbalancer("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4")
      member_manager.add_member("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4","4c507d81-299e-4b1c-a153-69d2b4573277", lb_existing.listeners[0].pool.members[0])

      expect{member_manager.add_member("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4","4c507d81-299e-4b1c-a153-69d2b4573277", lb_existing.listeners[0].pool.members[0])}.not_to raise_error


    end

  end
end