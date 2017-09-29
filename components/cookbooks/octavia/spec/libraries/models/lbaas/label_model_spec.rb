require File.expand_path('../../../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/label_model', __FILE__)

describe 'LabelModel' do
  context 'validate mutable properties' do
    subject(:loadbalancer) { LabelModel.new}

    context 'name' do
      it 'is within its maximum length' do
        large_string = 'a' * 255
        loadbalancer.name = large_string
        expect(loadbalancer.name.size).to be <= 255
      end
      it 'when above its maximum length will be truncated' do
        large_string = 'a' * 256
        loadbalancer.name = large_string
        expect(loadbalancer.name.length).to be <= 255
      end
    end

    context 'description' do
      it 'is within its maximum length' do
        large_string = 'a' * 255
        loadbalancer.description = large_string
        expect(loadbalancer.description.size).to be <= 255
      end
      it 'when above its maximum length will be truncated' do
        large_string = 'a' * 256
        loadbalancer.description = large_string
        expect(loadbalancer.description.size).to be <= 255
      end
    end
  end
end