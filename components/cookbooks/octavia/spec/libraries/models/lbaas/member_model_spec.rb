require File.expand_path('../../../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/member_model', __FILE__)
require 'rspec/expectations'

describe 'MemberModel' do

  context 'validate mutable properties' do
    subject(:member) { MemberModel.new('123.123.123.123', 80, 'subnet_id')}

    context 'weight' do
      it 'is string use default value' do
        member.weight = 'weight'
        expect(member.weight).to be == 1
      end
      it 'is above its maximum value' do
        member.weight = 257
        expect(member.weight).to be == 1
      end
      it 'is within its maximum value' do
        member.weight = 256
        expect(member.weight).to be <= 256
      end
      it 'is within its minimum value' do
        member.weight = 0
        expect(member.weight).to be >= 0
      end
      it 'is below its minimum value' do
        member.weight = -1
        expect(member.weight).to be == 1
      end
    end

    context "protocol_port" do
      subject(:member) { MemberModel.new('123.123.123.123', 80, 'subnet_id')}
      it 'is valid port ' do
        member.protocol_port ="56789"
        expect(member.protocol_port).to be == "56789"
      end
      it 'is invalid port' do
        expect { member.protocol_port ="89898989" }.to raise_error("protocol_port is invalid")
      end
    end
  end

  context 'serialize_optional_parameters' do
    it 'with tenant_id' do
      member = MemberModel.new('123.123.123.123', 80, 'subnet_id', 'tenant_id')
      expect(member.serialize_optional_parameters).to include(:tenant_id)
    end
    it 'without tenant_id' do
      member = MemberModel.new('123.123.123.123', 80, 'subnet_id', nil)
      expect(member.serialize_optional_parameters).not_to include(:tenant_id)
    end
  end

  context 'ip address is valid' do
    it 'ip address is in ipv4 format' do
      member = MemberModel.new('123.123.123.123', 80, 'subnet_id', 'tenant_id')
      expect(member.ip_address).to be == "123.123.123.123"
    end

    it 'ip address is in ipv6 format' do
      member = MemberModel.new('2620:1c0:72:8b00:f816:3eff:fe3d:8a44', 80, 'subnet_id', 'tenant_id')
      expect(member.ip_address).to be == "2620:1c0:72:8b00:f816:3eff:fe3d:8a44"
    end

    it 'ip address is nil' do
      expect{ MemberModel.new(nil, 80, 'subnet_id', 'tenant_id')}.to raise_error(ArgumentError)
    end

    it 'ip address is empty' do
      expect{ MemberModel.new("", 80, 'subnet_id', 'tenant_id')}.to raise_error(ArgumentError)
    end

    it 'ip address is in invalid ipv6 format' do
      expect{ MemberModel.new("620:1c0:72:8b00:f816:3eff:fe3d", 80, 'subnet_id', 'tenant_id')}.to raise_error(ArgumentError)
    end

    it 'ip address is in invalid ipv4 format' do
      expect{ MemberModel.new("1000:2:3:2", 80, 'subnet_id', 'tenant_id')}.to raise_error(ArgumentError)
    end

    it 'ip address is not an ip address' do
      expect{ MemberModel.new("167", 80, 'subnet_id', 'tenant_id')}.to raise_error(ArgumentError)
    end
  end
end