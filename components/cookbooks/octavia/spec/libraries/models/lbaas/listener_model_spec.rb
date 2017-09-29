require File.expand_path('../../../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/listener_model', __FILE__)
require 'rspec/expectations'

describe 'ListenerModel' do

  context 'protocol' do
    it 'that are valid' do
      %w(HTTP HTTPS TCP).each do |protocol|
        listener = ListenerModel.new(protocol, 80)
        expect(listener).to be_a ListenerModel
      end
    end

    it 'is not case-sensitive' do
      %w(http HTTP https HTTPS tcp TCP).each do |protocol|
        listener = ListenerModel.new(protocol, 80)
        expect(listener).to be_a ListenerModel
      end
    end

    it 'that are not valid to throw error' do
      %w(UDP ICMP).each do |protocol|
        expect{ListenerModel.new(protocol, 'ROUND_ROBIN')}.to raise_error(ArgumentError)
      end
    end
  end

  context 'portocol_port' do
    it 'cannot be alpha string' do
      expect { ListenerModel.new('http', 'abc') }.to raise_error(ArgumentError)
    end
    it 'can be an int' do
      listener = ListenerModel.new('http', 80)
      expect(listener.protocol_port).to be == 80
    end
    it 'is above its maximum value' do
      expect { ListenerModel.new('http', 65536) }.to raise_error(ArgumentError)
    end
    it 'is within its maximum value ' do
      listener = ListenerModel.new('http', 65534)
      expect(listener.protocol_port).to be <= 65535
    end
    it 'is within its minimum value' do
      listener = ListenerModel.new('http', 1)
      expect(listener.protocol_port).to be >= 0
    end
    it 'is below its minimum value' do
      expect { ListenerModel.new('http', -1) }.to raise_error(ArgumentError)
    end
  end

  context 'validate mutable properties' do
    subject(:listener) { ListenerModel.new('http', 80)}

    context 'label' do
      it 'is accessible via composition' do
        label = LabelModel.new
        label.name = 'name'
        listener.label = label
        expect(listener.label.name).to be == 'name'
      end
      it 'description is accessible via composition' do
        label = LabelModel.new
        label.description = 'description'
        listener.label = label
        expect(listener.label.description).to be == 'description'
      end
    end

    context 'connection_limit' do
      it 'cannot be a string' do
        listener.connection_limit = 'string value'
        expect(listener.connection_limit).to be == -1
      end
      it 'must be an int' do
        listener.connection_limit = 10
        expect(listener.connection_limit).to be == 10
      end
      it 'is above its maximum value' do
        listener.connection_limit = 2147483648
        expect(listener.connection_limit).to be == -1
      end
      it 'is within its maximum value' do
        listener.connection_limit = 2147483647
        expect(listener.connection_limit).to be == 2147483647
      end
      it 'is within its minimum value' do
        listener.connection_limit = -1
        expect(listener.connection_limit).to be == -1
      end
      it 'is below its minimum value' do
        listener.connection_limit = -2
        expect(listener.connection_limit).to be == -1
      end
    end
  end

  context 'serialize_optional_parameters' do
    it 'with tenant_id' do
      listener = ListenerModel.new('http', 80, 'tenant_id')
      expect(listener.serialize_optional_parameters).to include(:tenant_id)
    end

    it 'without tenant_id' do
      listener = ListenerModel.new('http', 80)
      expect(listener.serialize_optional_parameters).not_to include(:tenant_id)
    end
  end

  context 'protocol port via setter' do
    it 'is in the valid range' do
      listener = ListenerModel.new('http', 80)
      listener.protocol_port ="9090"
      expect(listener.protocol_port).to be == "9090"
    end
   end
end