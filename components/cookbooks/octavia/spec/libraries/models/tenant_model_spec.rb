require File.expand_path('../../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../../libraries/models/tenant_model', __FILE__)

describe 'TenantModel' do #todo this class needs to test the validation that is still missing

  context 'valid constructor' do
    subject(:tenant) { TenantModel.new('http://10.0.2.15:5000', 'tenant_name', 'username', 'password')}
    subject(:tenant2) { TenantModel.new('https://10.0.2.15:5000', 'tenant_name', 'username', 'password')}

    context 'the first parameter of the constructor "endpoint" will be parsed' do
      it 'scheme' do
        expect(tenant.scheme).to be == 'http'
      end
      it 'host' do
        expect(tenant.host).to be == '10.0.2.15'
      end
      it 'port' do
        expect(tenant.port).to be == '5000'
      end
    end

    context 'scheme' do
      it 'are valid protocols http' do
        expect(tenant.scheme).to be == 'http'
      end
      it 'are valid protocols https' do
        expect(tenant2.scheme).to be == 'https'
      end


    end

    it 'serialize_object returns valid json object' do
      tenant3 = TenantModel.new('http://10.0.2.15:5000', 'tenant_name', 'username', 'password')
      obj = tenant3.serialize_object

      expect(obj.nil?).to be false
    end

  end

   describe 'Loadbalancer manager test ' do

     endpoint = "https://10.246.241.101:5000/v3/auth/tokens/"
     tenant = "admin"
     username = "admin"
     password = "openstack123"


     context "With right set of inputs"

    it 'test initialze (constructor) for the class LoadBalancerManager with valid input' do

      tenant = TenantModel.new(endpoint, tenant, username, password)
      expect(tenant.nil?).to be false

    end

    context "With some of the inputs nil"

    it 'test initialze (constructor) for the class LoadBalancerManager with nil password for tenant' do

      expect { TenantModel.new(endpoint, tenant, username, nil)
      }.to raise_error(ArgumentError)

    end

    it 'test initialze (constructor) for the class LoadBalancerManager with nil username for tenant' do

      expect { TenantModel.new(endpoint, tenant, nil, password)
      }.to raise_error(ArgumentError)

    end

    it 'test initialze (constructor) for the class LoadBalancerManager with nil tenant name' do

      expect { TenantModel.new(endpoint, nil, username, password)
      }.to raise_error(ArgumentError)

    end

    it 'test initialze (constructor) for the class LoadBalancerManager with nil endpoint' do

      expect { TenantModel.new(nil, tenant, username, password)
      }.to raise_error(ArgumentError)

    end

  end



end