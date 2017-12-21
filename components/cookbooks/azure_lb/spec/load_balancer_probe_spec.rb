require File.expand_path('../../libraries/load_balancer.rb', __FILE__)
require File.expand_path('../../libraries/work_order_utils.rb', __FILE__)

require 'json'

describe 'probes and listeners' do

  context 'validation' do
    RSpec::Expectations.configuration.on_potential_false_positives = :nothing

    it 'should raise when there is no http ecv for a http listener' do
      wo = File.expand_path('workorders/http_no_match.json', File.dirname(__FILE__))
      node = JSON.parse(File.read(wo))
      work_order_utils = AzureLb::WorkOrder.new(node)

      expect{work_order_utils.validate_config}.to raise_exception
    end

    it 'should raise when lb method is not roundrobin or sourceiphash' do
      wo = File.expand_path('workorders/invalid_lb_method.json', File.dirname(__FILE__))
      node = JSON.parse(File.read(wo))
      work_order_utils = AzureLb::WorkOrder.new(node)

      expect{work_order_utils.validate_config}.to raise_exception
    end

    it 'should raise when persistence type is not sourceip when stickiness is selected' do
      wo = File.expand_path('workorders/invalid_stickiness.json', File.dirname(__FILE__))
      node = JSON.parse(File.read(wo))
      work_order_utils = AzureLb::WorkOrder.new(node)

      expect{work_order_utils.validate_config}.to raise_exception
    end

    it 'doesnt raise error when there is no ecv specified by user for a tcp listener' do
      wo = File.expand_path('workorders/tcp_no_match.json', File.dirname(__FILE__))
      node = JSON.parse(File.read(wo))
      work_order_utils = AzureLb::WorkOrder.new(node)

      expect{work_order_utils.validate_config}.not_to raise_exception
    end
    it 'doesnt raise error when there is no ecv specified by user for a https listener' do
      wo = File.expand_path('workorders/https_no_match.json', File.dirname(__FILE__))
      node = JSON.parse(File.read(wo))
      work_order_utils = AzureLb::WorkOrder.new(node)

      expect{work_order_utils.validate_config}.not_to raise_exception
    end
  end

  context 'selecting probe for a given listener' do
    it 'uses probe with port matching backend port of listener' do
      listener = {
          name: "lname",
          iport: 8080,
          iprotocol: 'http',
          vport: 'http',
          vprotocol: 8080
      }

      probes = []
      probes.push(
          {
              probe_name: "pname1",
              interval_secs: 15,
              num_probes: 3,
              port: 8080,
              protocol: 'http',
              request_path: '/'
          }
      )
      probes.push(
          {
              probe_name: "pname2",
              interval_secs: 15,
              num_probes: 3,
              port: 8081,
              protocol: 'http',
              request_path: 'another_health_check'
          }
      )

      found = AzureNetwork::LoadBalancer.get_probe_for_listener(listener, probes)
      expect(found).not_to be_nil
      expect(found[:probe_name]).to eq('pname1')
      expect(found[:port].to_i).to eq(8080)

    end

    context 'for listener with http backend' do
      it 'uses any http probe when no matching probe found' do
        listener = {
            name: "lname",
            iport: 8080,
            iprotocol: 'http',
            vport: 'http',
            vprotocol: 8080
        }

        probes = []
        probes.push(
            {
                probe_name: "pname1",
                interval_secs: 15,
                num_probes: 3,
                port: 8082,
                protocol: 'http',
                request_path: '/'
            }
        )
        probes.push(
            {
                probe_name: "pname2",
                interval_secs: 15,
                num_probes: 3,
                port: 8081,
                protocol: 'Tcp',
                request_path: 'nil'
            }
        )

        found = AzureNetwork::LoadBalancer.get_probe_for_listener(listener, probes)
        expect(found).not_to be_nil
        expect(found[:probe_name]).to eq('pname1')
        expect(found[:port].to_i).to eq(8082)

      end

      it 'returns nil when no matching probe and no http probe found' do
        listener = {
            name: "lname",
            iport: 8080,
            iprotocol: 'http',
            vport: 'http',
            vprotocol: 8080
        }

        probes = []
        probes.push(
            {
                probe_name: "pname",
                interval_secs: 15,
                num_probes: 3,
                port: 1234,
                protocol: 'Tcp',
                request_path: nil
            }
        )

        found = AzureNetwork::LoadBalancer.get_probe_for_listener(listener, probes)
        expect(found).to be_nil
      end
    end

    context 'for listener with tcp backend' do
      it 'creates a tcp probe when no matching probe found' do

        #the workorder didnt have probe for the tcp listener
        wo = File.expand_path('workorders/tcp_no_match.json', File.dirname(__FILE__))
        node = JSON.parse(File.read(wo))
        work_order_utils = AzureLb::WorkOrder.new(node)

        listener = JSON.parse(node['workorder']['rfcCi']['ciAttributes']['listeners'])[0]
        listener_port = (listener.split(' ')[3]).to_i

        probes = work_order_utils.ecvs
        found = probes.detect {|p| p[:port].to_i == listener_port}

        expect(probes.length).to eq(2)

        expect(found).not_to be_nil
        expect(found[:protocol]).to eq('Tcp')
        expect(found[:request_path]).to be_nil
      end

      it 'sets request path to nil on matching probe and uses it' do
        wo = File.expand_path('workorders/tcp_match.json', File.dirname(__FILE__))
        node = JSON.parse(File.read(wo))
        work_order_utils = AzureLb::WorkOrder.new(node)

        listener = JSON.parse(node['workorder']['rfcCi']['ciAttributes']['listeners'])[0]
        listener_port = (listener.split(' ')[3]).to_i

        probes = work_order_utils.ecvs
        found = probes.detect {|p| p[:port].to_i == listener_port}

        #when a match is found it is not creating a new one
        expect(probes.length).to eq(1)

        expect(found).not_to be_nil
        expect(found[:port].to_i).to eq(listener_port)
        expect(found[:request_path]).to be_nil
      end
    end

    context 'for listener with https backend' do
      it 'sets protocol on matching probe to Tcp and its request path to nil' do
        wo = File.expand_path('workorders/https_match.json', File.dirname(__FILE__))
        node = JSON.parse(File.read(wo))
        work_order_utils = AzureLb::WorkOrder.new(node)

        listener = JSON.parse(node['workorder']['rfcCi']['ciAttributes']['listeners'])[0]
        listener_port = (listener.split(' ')[3]).to_i

        probes = work_order_utils.ecvs
        found = probes.detect {|p| p[:port].to_i == listener_port}

        #when a match is found it is not creating a new one
        expect(probes.length).to eq(1)

        expect(found).not_to be_nil
        expect(found[:port].to_i).to eq(listener_port)
        expect(found[:request_path]).to be_nil
      end

      it 'creates tcp probe when no matching probe is found' do
        wo = File.expand_path('workorders/https_no_match.json', File.dirname(__FILE__))
        node = JSON.parse(File.read(wo))
        work_order_utils = AzureLb::WorkOrder.new(node)

        listener = JSON.parse(node['workorder']['rfcCi']['ciAttributes']['listeners'])[0]
        listener_port = (listener.split(' ')[3]).to_i

        probes = work_order_utils.ecvs
        found = probes.detect {|p| p[:port].to_i == listener_port}

        #when a match is not found a new probe is created.
        expect(probes.length).to eq(2)

        expect(found).not_to be_nil
        expect(found[:port].to_i).to eq(listener_port)
        expect(found[:request_path]).to be_nil
      end
    end
  end
end
