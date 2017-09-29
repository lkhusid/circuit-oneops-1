require File.expand_path('../../../../../spec/spec_helper', __FILE__)
require File.expand_path('../../../../../libraries/models/lbaas/base_model', __FILE__)

describe 'BaseModel' do
  context 'validate mutable properties' do
    subject(:base) { BaseModel.new}

    context 'admin_state_up' do
      it 'must be boolean' do
        base.admin_state_up=('non-boolean entry value')
        expect(base.admin_state_up).to be true
      end
      it 'can be false' do
        base.admin_state_up=(false)
        expect(base.admin_state_up).to be false
      end
    end

    it 'validate_port, protocol_port will be string must convert to int' do
      expect(base.send(:validate_port, "7878")).to be 7878
    end

    it 'validate_port, protocol_port is invalid' do
      expect { base.send(:validate_port,"89898988")}.to raise_error("port is invalid")
    end
  end
end