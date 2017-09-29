require File.expand_path('../../../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/session_persistence_model', __FILE__)
require 'rspec/expectations'

describe 'SessionPersistenceModel' do

  context 'type' do
    it 'are valid enum types' do
      %w(SOURCE_IP HTTP_COOKIE APP_COOKIE).each do |type|
        session_persistence_model = SessionPersistenceModel.new(type)
        expect(session_persistence_model.type).to be == type
      end
    end
    it 'should recognize all lower case words' do
      %w(source_ip http_cookie app_cookie).each do |type|
        session_persistence_model = SessionPersistenceModel.new(type)
        expect(session_persistence_model.type).to be == type.upcase
      end
     end
      it 'should not be nil' do
        expect {SessionPersistenceModel.new(nil)}.to raise_error(ArgumentError)
      end

      it 'should not be empty' do
        expect {SessionPersistenceModel.new("")}.to raise_error(ArgumentError)
      end
    end
    it 'should recognize SourceIP as SOURCE_IP' do
        session_persistence_model = SessionPersistenceModel.new('SourceIP')
        expect(session_persistence_model.type).to eq('SOURCE_IP')
    end
    it 'should recognize cookieinsert as HTTP_COOKIE' do
      session_persistence_model = SessionPersistenceModel.new('cookieinsert')
      expect(session_persistence_model.type).to eq('HTTP_COOKIE')
    end
  end

  context 'cookie_name' do
    it 'with APP_COOKIE type should be assinged' do
      session_persistence_model = SessionPersistenceModel.new('APP_COOKIE')
      session_persistence_model.cookie_name = 'SESSIONID'
      expect(session_persistence_model.cookie_name).to eq('SESSIONID')
    end
    it 'with SourceIP type should not be assigned' do
      session_persistence_model = SessionPersistenceModel.new('SourceIP')
      expect { session_persistence_model.cookie_name = 'SESSIONID' }.to raise_error(ArgumentError)
    end

    context 'cookie_name' do
      it 'throw exception on invalid cookie name' do
        expect { SessionPersistenceModel.new('RANDON_COOKIE') }.to raise_error("session_persistence_type is invalid")
      end
    end

      it 'serialize optional parameter should have cookie name' do
      session_persistence_model = SessionPersistenceModel.new('APP_COOKIE')
      session_persistence_model.cookie_name = 'SESSIONID'
      expect(session_persistence_model.serialize_optional_parameters).to include(:type, :cookie_name)
      end
  end

