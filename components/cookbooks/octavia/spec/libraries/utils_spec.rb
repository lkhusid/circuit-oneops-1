require File.expand_path('../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../libraries/utils', __FILE__)
require File.expand_path('../../../libraries/models/lbaas/loadbalancer_model', __FILE__)
require File.expand_path('../../../libraries/models/lbaas/listener_model', __FILE__)
require File.expand_path('../../../libraries/models/lbaas/pool_model', __FILE__)
require File.expand_path('../../../libraries/models/lbaas/member_model', __FILE__)
require File.expand_path('../../../libraries/models/lbaas/health_monitor_model', __FILE__)
require File.expand_path('../../../libraries/models/tenant_model', __FILE__)
require File.expand_path('../../../libraries/loadbalancer_manager', __FILE__)
require File.expand_path('../../../libraries/network_manager', __FILE__)
require File.expand_path('../../../libraries/utils', __FILE__)


describe 'Utils' do
  let(:fake_class) {Helpers::Fake_class.new()}


  context "initialize_health_monitor" do

    it 'should return health monitor object' do
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")

      expect(health_monitor.serialize_optional_parameters).to include(:name, :http_method, :expected_codes, :admin_state_up)
    end

    it 'should raise exception if no ecv is defined for iport ' do

      expect{initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "9090")}.to raise_error("No ECV defined for port 9090")
    end

    it 'should raise exception if no ecv is nil ' do
      expect{initialize_health_monitor("http", nil , "lb_name", "9090")}.to raise_error(ArgumentError)
    end

    it 'should raise exception if no ecv is empty ' do
      expect{initialize_health_monitor("http", "" , "lb_name", "9090")}.to raise_error(ArgumentError)
    end

  end

  context "initialize_pool" do

    it 'should return poolobject for valid inputs' do
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')

      pool = initialize_pool("http","Round Robin", "lb_name", members, health_monitor, false, "COOKIE")
      expect(pool.serialize_optional_parameters).to include(:lb_algorithm, :name)
    end

    it 'should raise exception for invalid lb algorithm' do
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')

      expect{initialize_pool("http","random", "lb_name", members, health_monitor, false, "COOKIE")}.to raise_error("lb_algorithm is invalid")
    end

    it 'should return poolobject for valid inputs with persistent enabled' do
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')

      pool = initialize_pool("http","Round Robin", "lb_name", members, health_monitor, true, "COOKIE")
      expect(pool.serialize_optional_parameters).to include(:lb_algorithm, :name)

    end


  end

  context "initialize_listener" do

    it 'should return listener for valid inputs' do
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')
      pool = initialize_pool("http","Round Robin", "lb_name", members, health_monitor, true, "COOKIE")
      container_ref = 'https://test.com:9311/v1/containers/a4622ffb-6312-4625-ae95-d40b407384c4'
      listener = initialize_listener("http", 80, "lb_name", pool, container_ref)

      expect(listener.serialize_optional_parameters).to include(:name)
    end

    it 'should raise exception for invalid vprotocol' do
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')
      pool = initialize_pool("http","Round Robin", "lb_name", members, health_monitor, true, "COOKIE")
      container_ref = 'https://test.com:9311/v1/containers/a4622ffb-6312-4625-ae95-d40b407384c4'

      expect{initialize_listener("httpsssss", 80, "lb_name", pool, container_ref)}.to raise_error("protocol is invalid")
    end

    it 'should raise exception for invalid vport' do
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')
      container_ref = 'https://test.com:9311/v1/containers/a4622ffb-6312-4625-ae95-d40b407384c4'

      pool = initialize_pool("http","Round Robin", "lb_name", members, health_monitor, true, "COOKIE")

      expect{initialize_listener("https", 29090909, "lb_name", pool, container_ref)}.to raise_error("protocol_port is invalid")
    end

  end


    context "initialize_loadbalancer" do

    it 'should return lb object for valid inputs' do
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")
      pool = initialize_pool("http","Round Robin", "lb_name", members, health_monitor, true, "COOKIE")
      container_ref = 'https://test.com:9311/v1/containers/a4622ffb-6312-4625-ae95-d40b407384c4'

      listener = initialize_listener("http", 80, "lb_name", pool, container_ref)
      lb =  initialize_loadbalancer("subnet_id","octavia","lb_name",listener)

      expect(listener.serialize_optional_parameters).to include(:name)
    end

    it 'should raise exception for nil lb name' do
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")

      pool = initialize_pool("http","Round Robin", "lb_name", members, health_monitor, true, "COOKIE")
      container_ref = 'https://test.com:9311/v1/containers/a4622ffb-6312-4625-ae95-d40b407384c4'

      listener = initialize_listener("http", 80, "lb_name", pool, container_ref)
      lb =  initialize_loadbalancer("subnet_id","octavia","lb_name",listener)

      expect{initialize_loadbalancer("subnet_id","octavia",nil,listener)}.to raise_error(StandardError)
    end

    it 'should return listener object even if listener is nil' do
      members=MemberModel.new('123.123.123.123', 80, 'subnet_id')
      health_monitor = initialize_health_monitor("http", "{\"8080\":\"GET /\"}", "lb_name", "8080")

      pool = initialize_pool("http","Round Robin", "lb_name", members, health_monitor, true, "COOKIE")
      container_ref = 'https://test.com:9311/v1/containers/a4622ffb-6312-4625-ae95-d40b407384c4'

      listener = initialize_listener("http", 80, "lb_name", pool, container_ref)
      lb =  initialize_loadbalancer("subnet_id","octavia","lb_name",listener)

      expect(initialize_loadbalancer("subnet_id","octavia","lb_name",nil).serialize_optional_parameters).to include(:name)
    end


  end
end