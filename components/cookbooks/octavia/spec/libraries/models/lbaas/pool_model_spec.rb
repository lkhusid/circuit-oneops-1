require File.expand_path('../../../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/pool_model', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/member_model', __FILE__)
require 'rspec/expectations'

describe 'PoolModel' do

  context 'protocol' do
    it 'that are valid' do
      %w(HTTP HTTPS TCP).each do |protocol|
        pool = PoolModel.new(protocol, 'ROUND_ROBIN')
        expect(pool).to be_a PoolModel
      end
    end
    it 'is not case-sensitive' do
      %w(http HTTP https HTTPS tcp TCP).each do |protocol|
        pool = PoolModel.new(protocol, 'ROUND_ROBIN')
        expect(pool).to be_a PoolModel
      end
    end
    it 'that are not valid to throw error' do
      %w(UDP ICMP).each do |protocol|
        expect{PoolModel.new(protocol, 'ROUND_ROBIN')}.to raise_error(ArgumentError)
      end
    end
  end

  context 'lb_algorithm' do
    context 'via constructor' do
      it 'are valid algorithms' do
        %w(ROUND_ROBIN LEAST_CONNECTIONS SOURCE_IP).each do |algorithm|
          pool = PoolModel.new('http', algorithm)
          expect(pool).to be_a PoolModel
        end
      end
      it 'that are not valid to throw error' do
        %w(RANDOM_CHOICE SHORTEST_PATH).each do |algorithm|
          expect{PoolModel.new('http', algorithm)}.to raise_error(ArgumentError)
        end
      end
      it 'are case insensitive' do
        %w(round_robin ROUND_ROBIN least_connections LEAST_CONNECTIONS source_ip SOURCE_IP).each do |algorithm|
          pool = PoolModel.new('http', algorithm)
          expect(pool).to be_a PoolModel
        end
      end
      it 'should recognize as single words' do
        pool = PoolModel.new('http', 'Round Robin')
        expect(pool.lb_algorithm).to be == 'ROUND_ROBIN'
      end
      it 'should recognize as compound word' do
        pool = PoolModel.new('http', 'RoundRobin')
        expect(pool.lb_algorithm).to be == 'ROUND_ROBIN'
      end
      it 'should recognize all lower case single words' do
        pool = PoolModel.new('http', 'round robin')
        expect(pool.lb_algorithm).to be == 'ROUND_ROBIN'
      end
    end
    context 'via setter' do
      subject(:pool) { PoolModel.new('http', 'ROUND_ROBIN')}
      it 'should recognize as single words' do
        pool.lb_algorithm = 'Round Robin'
        expect(pool.lb_algorithm).to be == 'ROUND_ROBIN'
      end
      it 'should recognize all lower case single words' do
        pool.lb_algorithm = 'round robin'
        expect(pool.lb_algorithm).to be == 'ROUND_ROBIN'
      end
      it 'should recognize pascalcase compound word' do
        pool.lb_algorithm = 'RoundRobin'
        expect(pool.lb_algorithm).to be == 'ROUND_ROBIN'
      end
      it 'should recognize lower case compound words' do
        pool.lb_algorithm = 'roundrobin'
        expect(pool.lb_algorithm).to be == 'ROUND_ROBIN'
      end
    end

    context "session persistence can be none" do
      subject(:pool) { PoolModel.new('http', 'ROUND_ROBIN')}

      it 'session persistence can be none' do
        pool.session_persistence ="none"
        expect(pool.session_persistence.nil?).to be true

      end

      it 'session persistence can be set' do
        pool.session_persistence =nil
        expect(pool.session_persistence).to be == nil
      end

      it 'session persistence can be set from session persistent object' do
        session_persistence_model = SessionPersistenceModel.new('cookieinsert')
        pool.session_persistence =(session_persistence_model.serialize_optional_parameters)
        expect(pool.session_persistence.nil?).to be false
      end

      it 'session persistence is invalid' do
        session_persistence_model = "abc"
        expect { pool.session_persistence =session_persistence_model}.to raise_error("session_persistence is invalid")
      end

    end
  end

  # context 'validate mutable properties' do
  #   subject(:pool) { PoolModel.new('http', 'ROUND_ROBIN')}
  #   it 'members should be an array' do
  #     member = MemberModel.new('pool_id', '123.123.123.123', 80, 'subnet_id')
  #     pool.members = [member]
  #     expect(pool.members).to be_an Array
  #   end
  # end

  context 'serialize_optional_parameters' do
    it 'with tenant_id' do
      pool = PoolModel.new('http', 'ROUND_ROBIN', 'tenant_id')
      expect(pool.serialize_optional_parameters).to include(:tenant_id)
    end

    it 'without tenant_id' do
      pool = PoolModel.new('http', 'ROUND_ROBIN', nil)
      expect(pool.serialize_optional_parameters).not_to include(:tenant_id)
    end
  end

end
