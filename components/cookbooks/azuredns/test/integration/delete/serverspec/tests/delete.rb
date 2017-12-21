# This spec has tests that validates a successfully completed oneops-azure deployment

describe 'DNS on azure' do
  before(:each) do
    @spec_utils = AzureSpecUtils.new($node)
    @resource_group_name = @spec_utils.get_resource_group_name
    @dns_attributes = @spec_utils.get_dns_attributes
  end

  context 'zone' do
    it 'should not exist' do
      zone_model = AzureDns::Zone.new(@dns_attributes, @resource_group_name)
      zone_exists = zone_model.check_for_zone

      expect(zone_exists).to eq(false)
    end
  end

  context 'record set' do
    it 'should not have the type A record' do
      record_set_model = AzureDns::RecordSet.new(@resource_group_name, @dns_attributes)
      record_set_name = @spec_utils.get_record_set_name
      RECORD_TYPE_A = 'A'.freeze
      record_set_exists = record_set_model.exists?(record_set_name, RECORD_TYPE_A)

      expect(record_set_exists).to eq(false)
    end
  end
end
