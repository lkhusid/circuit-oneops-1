require 'chef'
require File.expand_path('../../../azure_base/libraries/logger.rb', __FILE__)

module AzureNetwork
  # this class has all the methods in it to handle Azure's Network Security Group.
  class NetworkSecurityGroup
    attr_accessor :network_client

    def initialize(creds)
      @network_service = Fog::Network::AzureRM.new(creds)
    end

    def get(resource_group_name, network_security_group_name)
      @network_service.network_security_groups.get(resource_group_name, network_security_group_name)
    rescue MsRestAzure::AzureOperationError => e
      # If the error is that it doesn't exist, return nil
      OOLog.info("Error of Exception is: '#{e.body.values[0]}'")
      OOLog.info("Code of Exception is: '#{e.body.values[0]['code']}'")
      if e.body.values[0]['code'] == 'ResourceNotFound'
        OOLog.info('SECGROUP DOES NOT EXIST!!  Returning nil')
        return nil
      else
        OOLog.fatal("AzureOperationError Exception trying to get network security group #{network_security_group_name} Response: #{e.body}")
      end
    rescue => e
      OOLog.fatal("Azure::Network Security group - Exception trying to get network security group #{network_security_group_name} from resource group: #{resource_group_name}\n\rAzure::Network Security group - Exception is: #{e.message}")
    end

    def create(resource_group_name, net_sec_group_name, location)
      # Creates an empty network security group
      @network_service.network_security_groups.create(name: net_sec_group_name, resource_group: resource_group_name, location: location, security_rules: [])
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("AzureOperationError Exception trying to create network security group #{net_sec_group_name} response: #{e.body}")
    rescue => e
      OOLog.fatal("Exception trying to create network security group #{net_sec_group_name} #{e.body} Exception is: #{e.message}")
    end

    def create_update(resource_group_name, net_sec_group_name, parameters)
      @network_service.network_security_groups.create(name: net_sec_group_name, resource_group: resource_group_name, location: parameters.location, security_rules: parameters.security_rules)
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("AzureOperationError exception trying to create/update network security group #{net_sec_group_name} Error response: #{e.body}")
    rescue => e
      OOLog.fatal("Azure::Network Security group - Exception trying to create/update network security group #{net_sec_group_name} Exception: #{e.message}")
    end

    def list_security_groups(resource_group_name)
      @network_service.network_security_groups(resource_group: resource_group_name)
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("AzureOperationError exception trying to list network security groups from #{resource_group_name} resource group Response: #{e.body}")
    rescue => e
      OOLog.fatal("Exception trying to list network security groups from #{resource_group_name} resource group #{e.body} Exception is: #{e.message}")
    end

    def delete_security_group(resource_group_name, net_sec_group_name)
      nsg_exists = @network_service.network_security_groups.check_net_sec_group_exists(resource_group_name, net_sec_group_name)
      if !nsg_exists
        OOLog.info("The NSG #{net_sec_group_name} does not exist. Moving on...")
      else
        @network_service.network_security_groups.get(resource_group_name, net_sec_group_name).destroy
      end
    rescue MsRestAzure::AzureOperationError => e
      OOLog.info("AzureOperationError Error deleting NSG #{net_sec_group_name}")
      OOLog.info("Error response: #{e.body}") unless e.body.nil?
    rescue => e
      OOLog.fatal("Exception trying to delete network security group #{net_sec_group_name} Error body: #{e.body} Exception is: #{e.message}")
    end

    def create_or_update_rule(resource_group_name, network_security_group_name, security_rule_name, security_rule_parameters)
      # The Put network security rule operation creates/updates a security rule in the specified network security group group.
      @network_service.network_security_rules.create(
        name: security_rule_name,
        resource_group: resource_group_name,
        network_security_group_name: network_security_group_name,
        protocol: security_rule_parameters[:protocol],
        source_port_range: security_rule_parameters[:source_port_range],
        destination_port_range: security_rule_parameters[:destination_port_range],
        source_address_prefix: security_rule_parameters[:source_address_prefix],
        destination_address_prefix: security_rule_parameters[:destination_address_prefix],
        access: security_rule_parameters[:access],
        priority: security_rule_parameters[:priority],
        direction: security_rule_parameters[:direction]
      )
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("AzureOperationError trying to get the '#{security_rule_name}' Security Rule Response: #{e.body}")
    rescue => e
      OOLog.fatal("Exception trying to create/update security rule #{security_rule_name} #{e.body} Exception is: #{e.message}")
    end

    def delete_rule(resource_group_name, network_security_group_name, security_rule_name)
      # The delete network security rule operation deletes the specified network security rule.
      @network_service.network_security_rules.get(resource_group_name, network_security_group_name, security_rule_name).destroy
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("AzureOperationError Error trying to delete the '#{security_rule_name}' Security Rule - Response: #{e.body}")
    rescue => e
      OOLog.fatal("Exception trying to delete security rule #{security_rule_name} #{e.body} Exception is: #{e.message}")
    end

    def get_rule(resource_group_name, network_security_group_name, security_rule_name)
      # The Get NetworkSecurityRule operation retreives information about the specified network security rule.
      @network_service.network_security_rules.get(resource_group_name, network_security_group_name, security_rule_name)
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("Error trying to get the '#{security_rule_name}' Security Rule - Response: #{e.body}")
    rescue => e
      OOLog.fatal("Exception trying to get security rule #{security_rule_name} #{e.body} - Exception is: #{e.message}")
    end

    def list_rules(resource_group_name, network_security_group_name)
      # The List network security rule opertion retrieves all the security rules in a network security group.
      @network_service.network_security_rules(resource_group: resource_group_name, network_security_group_name: network_security_group_name)
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("AzureOperationError Error trying to listing Security Rules in '#{resource_group_name}' Response: #{e.body}")
    rescue => e
      OOLog.fatal("Exception trying to list security rules from securtiry group: #{network_security_group_name} #{e.body} - Exception: #{e.message}")
    end

    def self.create_rule_properties(security_rule_name, access, destination_address_prefix, destination_port_range, direction, priority, protocol, source_address_prefix, source_port_range)
      # 01 @security_rule_name Security group name
      # 02 @access SecurityRuleAccess allow or denied.
      # 03 @destination_address_prefix String source IP range
      # 04 @destination_port_range String range between 0 and 65535.
      # 05 @direction SecurityRuleDirection rule.InBound or Outbound.
      # 06 @priority Integer be between 100 and 4096.
      # 07 @protocol SecurityRuleProtocol applies to.
      # 08 @source_address_prefix String range.
      # 09 @source_port_range String between 0 and 65535.

      {
        name: security_rule_name,
        protocol: protocol,
        source_port_range: source_port_range,
        destination_port_range: destination_port_range,
        source_address_prefix: source_address_prefix,
        destination_address_prefix: destination_address_prefix,
        access: access,
        priority: priority,
        direction: direction
      }
    end

    def check_network_security_group_exists(resource_group_name, network_security_group_name)
      @network_service.network_security_groups.check_net_sec_group_exists(resource_group_name, network_security_group_name)
    rescue MsRestAzure::AzureOperationError => e
      OOLog.fatal("AzureOperationError Exception trying to check existence of network security group #{network_security_group_name} response: #{e.body}")
    rescue Exception => e
      OOLog.fatal("Exception trying to check existence of network security group #{network_security_group_name} #{e.body} Exception is: #{e.message}")
    end

    def create_nsg_rule(sec_rule_item, priority, description, nsg_name, rg_name)
      security_rule_access = Fog::ARM::Network::Models::SecurityRuleAccess::Allow
      security_rule_description = description
      security_rule_source_addres_prefix = sec_rule_item[3]
      security_rule_destination_port_range = sec_rule_item[1].to_s
      security_rule_direction = Fog::ARM::Network::Models::SecurityRuleDirection::Inbound
      security_rule_priority = priority
      security_rule_protocol = case sec_rule_item[2].downcase
                               when 'tcp'
                                 Fog::ARM::Network::Models::SecurityRuleProtocol::Tcp
                               when 'udp'
                                 Fog::ARM::Network::Models::SecurityRuleProtocol::Udp
                               else
                                 Fog::ARM::Network::Models::SecurityRuleProtocol::Asterisk
                               end
      security_rule_provisioning_state = nil
      security_rule_destination_addres_prefix = '*'
      security_rule_source_port_range = '*'
      security_rule_name = nsg_name + '-' + priority.to_s
      nsg_rule = {
                    name: security_rule_name,
                    resource_group: rg_name,
                    protocol: security_rule_protocol,
                    network_security_group_name: nsg_name,
                    source_port_range: security_rule_source_port_range,
                    destination_port_range: security_rule_destination_port_range,
                    source_address_prefix: security_rule_source_addres_prefix,
                    destination_address_prefix: security_rule_destination_addres_prefix,
                    access: security_rule_access,
                    priority: security_rule_priority,
                    direction: security_rule_direction
                  }
      nsg_rule
    end

    def get_sec_rules(node, nsg_name, rg_name)
      # Creating security rules objects
      rules = node['secgroup']['inbound'].tr('"[]\\', '').split(',')
      sec_rules = []
      priority = 100
      description = node['secgroup']['description']
      reg_ex = /(\d+|\*|\d+-\d+)\s(\d+|\*|\d+-\d+)\s([A-Za-z]+|\*)\s\S+/
      rules.each do |item|
        raise "#{item} is not a valid security rule" unless reg_ex.match(item)
        item2 = item.split(' ')
        nsg_rule = create_nsg_rule(item2, priority, description, nsg_name, rg_name)
        sec_rules << nsg_rule
        priority += 100
      end
      sec_rules
    end

    def match_nsg_rules(nsg_list, sec_rules)
      nsg_list.each do |nsg|
        next unless nsg.security_rules.count == sec_rules.count
        rules_matched = 0
        sec_rules.each do |sec_rule|
          nsg.security_rules.each do |nsg_rule|
            next unless nsg_rule.protocol == sec_rule[:protocol] &&
                        nsg_rule.source_port_range == sec_rule[:source_port_range] &&
                        nsg_rule.destination_port_range == sec_rule[:destination_port_range] &&
                        nsg_rule.source_address_prefix == sec_rule[:source_address_prefix] &&
                        nsg_rule.destination_address_prefix == sec_rule[:destination_address_prefix] &&
                        nsg_rule.access == sec_rule[:access] &&
                        nsg_rule.direction == sec_rule[:direction] &&
                        nsg_rule.priority == sec_rule[:priority]
            rules_matched += 1
          end
        end

        if rules_matched == sec_rules.count
          puts "***RESULT:net_sec_group_id=#{nsg.id}"
          return nsg.id
        end
      end
      nil
    end

    def get_matching_nsgs(nsg_list, pack_name)
      matched_nsgs = []
      nsg_list.each do |nsg|
        matched_nsgs << nsg if nsg.name.include? "#{pack_name}_"
      end
      matched_nsgs
    end
    # end of class
  end
  # end of module
end
