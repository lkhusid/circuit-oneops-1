COOKBOOKS_PATH = "/opt/oneops/inductor/circuit-oneops-1/components/cookbooks"

require 'fog/azurerm'
require "#{COOKBOOKS_PATH}/azure_lb/libraries/load_balancer.rb"
require "#{COOKBOOKS_PATH}/azure_lb/libraries/work_order_utils.rb"
require "#{COOKBOOKS_PATH}/azure_base/libraries/utils.rb"
Dir.glob("#{COOKBOOKS_PATH}/azure/libraries/*.rb").each {|lib| require lib}

#load spec utils
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_spec_utils"
require "#{COOKBOOKS_PATH}/azure_base/test/integration/azure_lb_spec_utils"

describe 'azure lb' do
  before(:each) do
    @spec_utils = AzureLBSpecUtils.new($node)
    @work_order_utils = AzureLb::WorkOrder.new($node)
  end

  it 'should exist' do
    lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
    load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

    expect(load_balancer).not_to be_nil
    expect(load_balancer.name).to eq(@spec_utils.get_lb_name)
  end

  it "has oneops org and assembly tags" do
    if !$node['workorder'].has_key?("actionName")
      tags_from_work_order = Utils.get_resource_tags($node)
      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

      tags_from_work_order.each do |key, value|
        expect(load_balancer.tags).to include(key => value)
      end
    end
  end

  it 'its backend address pool contains all computes from workorder' do
    resource_group_name = @spec_utils.get_resource_group_name
    lb_name = @spec_utils.get_lb_name

    #get nics attached to load balancer.
    lb_backend_ipconfigs = @spec_utils.get_backend_ip_configurations(resource_group_name, lb_name)
    lb_backend_ipconfig_ids = lb_backend_ipconfigs.map {|backend_ipconfig| backend_ipconfig.id}


    #get nics attached to computes that are listed in workorder. all these nics should be in loadbalancer's backend address pool
    creds = @spec_utils.get_azure_creds
    vm_svc = AzureCompute::VirtualMachine.new(creds)
    nic_svc = AzureNetwork::NetworkInterfaceCard.new(creds)
    nic_svc.rg_name = resource_group_name
    nics_attchd_computes_from_wo = []

    computes_from_wo = @work_order_utils.compute_nodes
    computes_from_wo.each do |compute|
      vm = vm_svc.get(resource_group_name, compute[:instance_name])
      nic_name = nic_svc.get_nic_name(vm.network_interface_card_ids[0])
      nic = nic_svc.get(nic_name)
      nics_attchd_computes_from_wo.push(nic)
    end

    expect(lb_backend_ipconfig_ids.count).to eq(nics_attchd_computes_from_wo.count)

    nics_attchd_computes_from_wo.each do |nic|
      expect(lb_backend_ipconfig_ids).to include(nic.ip_configuration_id)
    end
  end

  it 'valid load distribution method is set on lb rules' do
    expected_load_distribution = @work_order_utils.load_distribution

    lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
    load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

    load_balancer.load_balancing_rules.each do |lb_rule|
      expect(lb_rule.load_distribution).to eq(expected_load_distribution)
    end
  end

  context 'probes' do
    it 'protocol is set to http when there is no listener with same backend port' do
      listeners_from_wo = @work_order_utils.listeners

      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)
      probes = load_balancer.probes

      probes.each do |p|
        listener = listeners_from_wo.detect {|l| l[:iport].to_i == p.port}
        if listener.nil?
          expect(p.protocol.downcase).to eq('http')
        end
      end
    end

    it 'protocol is set to tcp for a matching https listener' do
      listeners_from_wo = @work_order_utils.listeners

      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)
      probes = load_balancer.probes

      probes.each do |p|
        listener = listeners_from_wo.detect {|l| l[:iport].to_i == p.port}

        if !listener.nil? && listener[:iprotocol].downcase == 'https'
          expect(p.protocol.downcase).to eq('tcp')
        end
      end
    end

    it 'protocol is set to backend protocol of a matching listener' do
      listeners_from_wo = @work_order_utils.listeners

      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)
      probes = load_balancer.probes

      probes.each do |p|
        listener = listeners_from_wo.detect {|l| l[:iport].to_i == p.port}

        if !listener.nil?
          expected_probe_protocol = 'http'
          if listener[:iprotocol].downcase == 'https' || listener[:iprotocol].downcase == 'tcp'
            expected_probe_protocol = 'tcp'
          end
          expect(p.protocol.downcase).to eq(expected_probe_protocol)
        end
      end
    end

  end

  context 'listeners' do
    it 'every listener has a probe attached to it' do
      listeners_from_wo = @work_order_utils.listeners
      lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
      load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

      listeners_from_wo.each do |l|
        az_lb_rule = load_balancer.load_balancing_rules.detect {|r| r.frontend_port.to_i == l[:vport].to_i}
        expect(az_lb_rule.probe_id).not_to be_nil
        expect(az_lb_rule.probe_id).not_to be_empty
      end
    end

    context 'http listener' do
      it 'uses a http probe' do
        listeners_from_wo = @work_order_utils.listeners
        lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
        load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

        listeners_from_wo.each do |l|
          if l[:iprotocol].downcase == 'http'
            az_lb_rule = load_balancer.load_balancing_rules.detect {|r| r.frontend_port.to_i == l[:vport].to_i}
            az_lb_rule_probe_name = Hash[*(az_lb_rule.probe_id.split('/'))[1..-1]]['probes']
            az_lb_rule_probe = load_balancer.probes.detect {|p| p.name == az_lb_rule_probe_name}

            expect(az_lb_rule_probe.protocol.downcase == 'http')
          end
        end
      end

      it 'uses any http probe when a probe with same port is not found' do
        lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
        load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

        listeners_from_wo = @work_order_utils.listeners
        ecvs_from_wo = @work_order_utils.ecvs

        listeners_from_wo.each do |l|
          if l[:iprotocol].downcase == 'http'
            ecv = ecvs_from_wo.detect {|ecv| ecv[:port].to_i == l[:iport].to_i}
            if ecv.nil?
              az_lb_rule = load_balancer.load_balancing_rules.detect {|r| r.frontend_port.to_i == l[:vport].to_i}
              az_lb_rule_probe_name = Hash[*(az_lb_rule.probe_id.split('/'))[1..-1]]['probes']
              az_lb_rule_probe = load_balancer.probes.detect {|p| p.name == az_lb_rule_probe_name}

              expect(az_lb_rule_probe).not_to be_nil
              expect(az_lb_rule_probe.protocol.downcase).to eq('http')
            end
          end
        end
      end
    end

    context 'tcp listener' do
      it 'uses a tcp probe' do
        listeners_from_wo = @work_order_utils.listeners
        lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
        load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

        listeners_from_wo.each do |l|
          if l[:iprotocol].downcase == 'tcp'
            az_lb_rule = load_balancer.load_balancing_rules.detect {|r| r.frontend_port.to_i == l[:vport].to_i}
            az_lb_rule_probe_name = Hash[*(az_lb_rule.probe_id.split('/'))[1..-1]]['probes']
            az_lb_rule_probe = load_balancer.probes.detect {|p| p.name == az_lb_rule_probe_name}

            expect(az_lb_rule_probe.protocol.downcase == 'tcp')
          end
        end
      end
    end

    context 'https listener' do
      it 'uses a tcp probe' do
        listeners_from_wo = @work_order_utils.listeners
        lb_svc = AzureNetwork::LoadBalancer.new(@spec_utils.get_azure_creds)
        load_balancer = lb_svc.get(@spec_utils.get_resource_group_name, @spec_utils.get_lb_name)

        listeners_from_wo.each do |l|
          if l[:iprotocol].downcase == 'https'
            az_lb_rule = load_balancer.load_balancing_rules.detect {|r| r.frontend_port.to_i == l[:vport].to_i}
            az_lb_rule_probe_name = Hash[*(az_lb_rule.probe_id.split('/'))[1..-1]]['probes']
            az_lb_rule_probe = load_balancer.probes.detect {|p| p.name == az_lb_rule_probe_name}

            expect(az_lb_rule_probe.protocol.downcase == 'tcp')
          end
        end
      end
    end

  end

end