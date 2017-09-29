require 'fog'
require 'time'

class DrsRuleManager

  ZONE_NAME = 'oneops-zone-'

  def initialize(compute_provider, service_compute)
    fail ArgumentError, 'compute_provider cannot be nil' if compute_provider.nil?
    fail ArgumentError, 'service_compute cannot be nil' if service_compute.nil?

    @compute_provider = compute_provider
    @datacenter = service_compute[:datacenter]
    @cluster = service_compute[:cluster]
    @availability_zones = []
  end

  def availability_zones
    if @availability_zones.empty?
      @availability_zones = get_availability_zones
    end
    return @availability_zones
  end

  attr_reader :datacenter, :cluster, :name, :vm_ids, :type, :enabled

  def create_one_hostgroup_per_vhost
    host_groups = get_hostgroups_to_create
    if !host_groups.nil? && !host_groups.empty?
      Chef::Log.info("creating availibility zones")
      create_host_groups(host_groups)
    else
      Chef::Log.info("availibility zones already exist")
    end
  end

  def get_hostgroups_to_create
    hosts = @compute_provider.list_hosts(get_base_attributes)
    groups = @compute_provider.list_groups(get_base_attributes)

    host_groups = Hash.new
    num = 0
    hosts.each do |host|
      num += 1
      host_group_name = ZONE_NAME + num.to_s
      host_group_exist = false
      groups.each do |group|
        if (group[:type].to_s == 'ClusterHostGroup') && (group[:name] == host_group_name)
          host_group_exist = true
        end
      end
      if host_group_exist == false
        host_refs = Array.new
        host_ref = @compute_provider.get_host(host[:name], @cluster, @datacenter).to_s.match('(host-)\d{3}').to_s
        host_refs.push(host_ref)
        host_groups["#{host_group_name}"] = host_refs
      end
    end
    return host_groups
  end
  private :get_hostgroups_to_create

  def get_base_attributes
    attributes = {}
    attributes[:datacenter] = @datacenter
    attributes[:cluster] = @cluster
    return attributes
  end
  private :get_base_attributes

  def create_host_groups(host_groups)
    fail ArgumentError, 'host_groups is invalid' if host_groups.nil? || host_groups.empty?

    attributes = get_base_attributes
    host_groups.each do |group_name,host_refs|
      attributes[:type] = RbVmomi::VIM::ClusterHostGroup
      attributes[:name] = group_name
      attributes[:host_refs] = host_refs
      Chef::Log.info('creating hostgroup: ' + group_name)
      begin
        result = @compute_provider.create_group(attributes)
      rescue => e
        Chef::Log.error('Creating hostgroup failed: ' + e.to_s)
        exit 1
      end
    end
  end
  private :create_host_groups

  def create_drs_rules(vmgroup_name_prefix, vm_name_prefix, platform_ci_id, requires_computes)
    fail ArgumentError, 'vmgroup_name_prefix is invalid' if vmgroup_name_prefix.nil? || vmgroup_name_prefix.empty?
    fail ArgumentError, 'vm_name_prefix is invalid' if vm_name_prefix.nil? || vm_name_prefix.empty?
    fail ArgumentError, 'platform_ci_id is invalid' if platform_ci_id.nil?
    fail ArgumentError, 'requires_computes is invalid' if requires_computes.nil?

    vmgroups = get_vmgroups(vmgroup_name_prefix, vm_name_prefix, platform_ci_id, requires_computes)
    is_vms_deployed = validate_vms_deployed(vmgroups)
    create_vm_groups(vmgroups) if is_vms_deployed == true
    is_vmgroups_created = validate_vmgroups_created(vmgroup_name_prefix, requires_computes)
    create_rules(vmgroups) if is_vmgroups_created == true
  end

  def create_vm_groups(vmgroups)
    fail ArgumentError, 'vmgroups is invalid' if vmgroups.nil?

    attributes = get_base_attributes
    attributes[:type] = RbVmomi::VIM::ClusterVmGroup
    vmgroups.each do |key,value|
      attributes[:name] = key
      attributes[:vm_ids] = value
      Chef::Log.info('creating vmgroup: ' + key + ' with following = ' + value.to_s)
      begin
        @compute_provider.create_group(attributes)
      rescue => e
        if e.to_s == 'Group ' + key + ' already exists!' || e.to_s =~ /InvalidArgument: A specified parameter was not correct./
          Chef::Log.warn('Group ' + key + ' already exists!')
        else
          Chef::Log.warn('Failed creating vmgroup: ' + e.to_s)
          exit 1
        end
      end
    end
  end
  private :create_vm_groups

  def validate_vms_deployed(vmgroups)
    fail ArgumentError, 'vmgroups is invalid' if vmgroups.nil?

    is_vms_deployed = false
    vm_total = vm_found = 0
    Chef::Log.info("checking if system is ready for creating vmgroups")
    vmgroups.each_key do |key|
      vmgroups[key].each do |vm_name|
        vm_total += 1
        begin
          response = @compute_provider.get_virtual_machine(vm_name)
          ipaddress = response['ipaddress'] if !response.nil?
          vm_found += 1 if !ipaddress.nil?
        rescue
          is_vms_deployed = false
        end
      end
    end
    is_vms_deployed = true if vm_total == vm_found
    if is_vms_deployed == false
      Chef::Log.info("not ready, another process will create vmgroups")
    end
    return is_vms_deployed
  end
  private :validate_vms_deployed

  def get_vmgroups(vmgroup_name_prefix, vm_name_prefix, platform_ci_id, requires_computes)
    fail ArgumentError, 'vmgroup_name_prefix is invalid' if vmgroup_name_prefix.nil? || vmgroup_name_prefix.empty?
    fail ArgumentError, 'vm_name_prefix is invalid' if vm_name_prefix.nil? || vm_name_prefix.empty?
    fail ArgumentError, 'platform_ci_id is invalid' if platform_ci_id.nil?
    fail ArgumentError, 'requires_computes is invalid' if requires_computes.nil?

    hash = Hash.new
    requires_computes.each do |requires_compute|
      instance_index = requires_compute[:ciName].split("-").last.to_i + platform_ci_id
      index = instance_index % availability_zones.size
      vmgroup_name = vmgroup_name_prefix + '_' + availability_zones[index]
      instance_name = vm_name_prefix + '-' + requires_compute[:ciId].to_s
      if !hash.has_key?(vmgroup_name)
        hash[vmgroup_name] = [instance_name]
      else
        array = Array.new
        hash[vmgroup_name].each do |compute_name|
          array.push(compute_name)
        end
        array.push(instance_name)
        hash[vmgroup_name] = array
      end
    end
    return hash
  end
  private :get_vmgroups

  def validate_vmgroups_created(vmgroup_name_prefix, requires_computes)
    fail ArgumentError, 'vmgroup_name_prefix is invalid' if vmgroup_name_prefix.nil? || vmgroup_name_prefix.empty?

    is_vmgroups_created = false
    vmgroup_regex = vmgroup_name_prefix[0...-1]
    vmgroups_found = 0
    Chef::Log.info("checking if system is ready for creating drs rules")
    groups = @compute_provider.list_groups(get_base_attributes)
    groups.each do |group|
      if (group[:type].to_s == 'ClusterVmGroup') && (group[:name] =~ /#{vmgroup_regex}/)
        vmgroups_found += 1
      end
    end

    if requires_computes.size < availability_zones.size
      total_vmgroups = requires_computes.size
    else
      total_vmgroups = availability_zones.size
    end
    is_vmgroups_created = true if vmgroups_found == total_vmgroups
    if is_vmgroups_created == false
      Chef::Log.info("not ready, another process will create vmgroups")
    end

    return is_vmgroups_created
  end
  private :validate_vmgroups_created

  def create_rules(vmgroups)
    fail ArgumentError, 'vmgroups is invalid' if vmgroups.nil?

    vmgroups.each do |key,value|
      hostgroup_name = key.split('_').last.to_s
      attributes = get_rule_attributes(key.to_s.strip, hostgroup_name)
      Chef::Log.info('creating rule: ' + key.to_s)
      begin
        @compute_provider.create_rule(attributes)
      rescue => e
        Chef::Log.warn('exception: ' + e.to_s)
      end
    end
  end
  private :create_rules

  def get_rule_attributes(vmgroup_name, hostgroup_name = nil)
    attributes = get_base_attributes
    attributes[:name] = vmgroup_name
    attributes[:enabled] = true
    attributes[:type] = RbVmomi::VIM::ClusterVmHostRuleInfo
    attributes[:mandatory] = false
    attributes[:vmGroupName] = vmgroup_name
    attributes[:affineHostGroupName] = hostgroup_name
    return attributes
  end
  private :get_rule_attributes

  def remove_drs_rules(vmgroup_name)
    fail ArgumentError, 'vmgroup_name is invalid' if vmgroup_name.nil? || vmgroup_name.empty?

    is_vmgroup_empty = validate_empty_vmgroup(vmgroup_name)
    destroy_vm_group(vmgroup_name) if is_vmgroup_empty == true
    destroy_rule(vmgroup_name) if is_vmgroup_empty == true    
  end

  def validate_empty_vmgroup(vmgroup_name)
    fail ArgumentError, 'vmgroup_name is invalid' if vmgroup_name.nil? || vmgroup_name.empty?

    is_vmgroup_empty = false
    vm_ids_found = 0
    Chef::Log.info("checking if vmgroup " + vmgroup_name + " is empty")
    groups = @compute_provider.list_groups(get_base_attributes)
    groups.each do |group|
      if (group[:type].to_s == 'ClusterVmGroup') && (group[:name] == vmgroup_name)
        group[:vm_ids].each do |vm_id|
          vm_ids_found += 1
        end
      end
    end
    is_vmgroup_empty = true if vm_ids_found == 0
    if is_vmgroup_empty == true
      Chef::Log.info("vmgroup is empty")
    else
      Chef::Log.info("vmgroup not empty")
    end
    return is_vmgroup_empty
  end
  private :validate_empty_vmgroup

  def destroy_rule(vmgroup_name)
    fail ArgumentError, 'vmgroup_name is invalid' if vmgroup_name.nil? || vmgroup_name.empty?

    attributes = get_rule_attributes(vmgroup_name)
    rules = @compute_provider.list_rules(attributes)
    rule_key = nil
    rules.each do |rule|
      rule_key = rule[:key] if rule[:name] == vmgroup_name
    end
    attributes[:key] = rule_key

    Chef::Log.info('deleting drs rule: ' + vmgroup_name)
    begin
      @compute_provider.destroy_rule(attributes)
    rescue => e
      if (e.to_s == 'InvalidArgument: A specified parameter was not correct.') || (e.to_s == 'uninitialized constant Fog::Vsphere::Error')
        Chef::Log.warn('Not Found: ' + vmgroup_name)
      else
        Chef::Log.error('Failed deleting drs rule: ' + e.to_s)
        exit 1
      end
    end
  end

  def destroy_vm_group(vmgroup_name)
    attributes = get_base_attributes
    attributes[:type] = RbVmomi::VIM::ClusterVmGroup
    attributes[:name] = vmgroup_name

    Chef::Log.info('deleting drs vmgroup: ' + vmgroup_name)
    begin
      result = @compute_provider.destroy_group(attributes)
    rescue => e
      if (e.to_s == 'InvalidArgument: A specified parameter was not correct.') || (e.to_s == 'uninitialized constant Fog::Vsphere::Error')
        Chef::Log.warn('Not Found: ' + vmgroup_name)
      else
        Chef::Log.error('Failed deleting drs vmgroup: ' + e.to_s)
        exit 1
      end
    end
  end

  def get_availability_zones
    availibility_zones = Array.new
    groups = @compute_provider.list_groups(get_base_attributes)
    groups.each do |group|
      if (group[:type].to_s == 'ClusterHostGroup') && (group[:name] =~ /#{ZONE_NAME}/)
        availibility_zones.push(group[:name])
      end
    end
    return availibility_zones
  end
  private :get_availability_zones

end
