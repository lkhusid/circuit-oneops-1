  require 'simplecov'
  require 'webmock/rspec'


  require File.expand_path('../../../spec/spec_helper', __FILE__)
  require File.expand_path('../../../libraries/models/tenant_model', __FILE__)
  require File.expand_path('../../../libraries/loadbalancer_manager', __FILE__)
  require File.expand_path('../../../libraries/health_monitor_manager', __FILE__)

  require File.expand_path('../../../libraries/network_manager', __FILE__)
  require File.expand_path('../manager_spec_helper',__FILE__)

  describe 'HealthMonitorManager' do
    let(:lb) {Helpers::Helper.new}
    include Helpers
    context 'Health Monitor Manager'


    subject(:tenant) { TenantModel.new('http://10.0.2.15:5000', 'tenant_name', 'username', 'password')}

    it 'should test health monitor manager constructor' do
      token_helper
      parent_helper_method
      HMmanager = HealthMonitorManager.new(tenant)
      expect(HMmanager.nil?).to be false
    end


      it 'should test update_health_monitor with valid arguments' do
        token_helper
        parent_helper_method
        HMmanager = HealthMonitorManager.new(tenant)
        lb_obj= lb.get_lb()
        expect{ HMmanager.update_healthmonitor("8e5aee5f-5dda-43bc-809c-fd5ee2a191e4", "ad1236b9-b490-44c9-bfe8-48beb86e3130", lb_obj.listeners[0].pool.health_monitor)}.to_not raise_error
      end
  end