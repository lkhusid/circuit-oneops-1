# This spec has tests that validates a successfully completed oneops-azure deployment

describe 'DNS on Azure' do
  before(:context) do
    @spec_utils = AzureSpecUtils.new($node)
    @resource_group_name = @spec_utils.get_resource_group_name
    @dns_attributes = @spec_utils.get_dns_attributes
  end

  context 'zone' do
    it 'should exist' do
      zone_model = AzureDns::Zone.new(@dns_attributes, @resource_group_name)
      zone_exists = zone_model.check_for_zone

      expect(zone_exists).to eq(true)
    end
  end

  context 'record set' do
    before(:each) do
      @record_set_model = AzureDns::RecordSet.new(@resource_group_name, @dns_attributes)
      @record_set_name = @spec_utils.get_record_set_name
      @RECORD_TYPE_A = 'A'.freeze
    end

    it 'should have type A record' do
      record_set_exists = @record_set_model.exists?(@record_set_name, @RECORD_TYPE_A)

      expect(record_set_exists).to eq(true)
    end

    it 'should have equal count of IPs as for VMs/LBs' do
      dns_ip_records = @record_set_model.get_existing_records_for_recordset(@RECORD_TYPE_A, @record_set_name)
      ip_addresses = @spec_utils.lb_exists? ? @spec_utils.get_lb_public_ip : @spec_utils.get_all_vms_public_ips

      expect(dns_ip_records.count).to eq(ip_addresses.count)
    end

    it 'should have public IPs of all existing VMs/LBs' do
      dns_ip_records = @record_set_model.get_existing_records_for_recordset(@RECORD_TYPE_A, @record_set_name)
      ip_addresses = @spec_utils.lb_exists? ? @spec_utils.get_lb_public_ip : @spec_utils.get_all_vms_public_ips

      ip_addresses.each do |ip_address|
        expect(dns_ip_records).to include(ip_address)
      end
    end
  end
end
