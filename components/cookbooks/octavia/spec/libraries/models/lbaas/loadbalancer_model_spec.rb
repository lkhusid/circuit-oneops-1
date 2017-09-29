require File.expand_path('../../../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/loadbalancer_model', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/label_model', __FILE__)

describe 'LoadbalancerModel' do

  context 'validate mutable properties' do
    subject(:loadbalancer) { LoadbalancerModel.new('vip_subnet_id')}

    context 'label' do
      it 'is accessible via composition' do
        label = LabelModel.new
        label.name = 'name'
        loadbalancer.label = label
        expect(loadbalancer.label.name).to be == 'name'
      end
      it 'description is accessible via composition' do
        label = LabelModel.new
        label.description = 'description'
        loadbalancer.label = label
        expect(loadbalancer.label.description).to be == 'description'
      end
    end

    context 'subnet_id is invalid' do
      it 'subnet_id is nil' do
        expect { LoadbalancerModel.new(nil)}.to raise_error(ArgumentError)
      end
      it 'subnet_id is empty' do
        expect { LoadbalancerModel.new("")}.to raise_error(ArgumentError)
      end
    end
  end

  context 'serialize_optional_parameters with' do
    subject(:loadbalancer) { LoadbalancerModel.new('vip_subnet_id', nil, 'tenant_id', 'vip_address') }

    it 'tenant_id' do
      expect(loadbalancer.serialize_optional_parameters).to include(:tenant_id)
    end
    it 'vip_address' do
      expect(loadbalancer.serialize_optional_parameters).to include(:vip_address)
    end
  end

  context 'serialize_optional_parameters without' do
    subject(:loadbalancer) { LoadbalancerModel.new('vip_subnet_id') }

    it 'tenant_id' do
      expect(loadbalancer.serialize_optional_parameters).not_to include(:tenant_id)
    end
    it 'vip_address' do
      expect(loadbalancer.serialize_optional_parameters).not_to include(:vip_address)
    end
  end

end