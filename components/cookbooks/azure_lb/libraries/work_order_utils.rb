module AzureLb
  class WorkOrder

    def initialize(node)
      @node = node
    end

    def ecvs
      @ecvs || @ecvs = get_ecvs_from_wo
    end

    def listeners
      @listeners || @listeners = get_listeners_from_wo
    end

    def compute_nodes
      @compute_nodes || @compute_nodes = get_compute_nodes_from_wo
    end

    def load_distribution
      load_distribution = ''
      ci_attribs = @node['workorder'].has_key?('rfcCi') ? @node['workorder']['rfcCi']['ciAttributes'] : @node['workorder']['ci']['ciAttributes']
      lb_method = ci_attribs['lbmethod']
      stickiness = ci_attribs['stickiness']
      persistence_type = ci_attribs['persistence_type']

      if lb_method == 'roundrobin'
        load_distribution = 'Default'
      elsif lb_method == 'sourceiphash'
        load_distribution = 'SourceIP'
      end

      if stickiness == 'true'
        if persistence_type == 'sourceip'
          load_distribution = 'SourceIP'
        end
      end

      return load_distribution
    end

    def validate_config
      validate_load_distribution_config
    end

    def get_ecvs_from_wo
      ci = @node['workorder'].key?('rfcCi') ? @node['workorder']['rfcCi'] : @node['workorder']['ci']
      ecvs = []
      interval_secs = 15
      num_probes = 3
      ecvs_raw = JSON.parse(ci['ciAttributes']['ecv_map'])

      # Iterate through listeners, we need to create a default TCP health probe if
      # one does not exist
      listeners.each do |l|
        the_probe = nil
        ecvs_raw.each_pair do |k,v|

          if k == l[:iport]
            the_probe = v
            break
          end
        end

        if the_probe
          # Check if value in ecv_map actually contains hash, then treat it accordingly
          begin
            json_arr = JSON.parse(the_probe)
            # if what we have is a hash - convert to 1-item array
            json_arr = [json_arr] if json_arr.is_a?(Hash)
          rescue JSON::ParserError => e
            json_arr = nil
          end

          if json_arr
            mandatory_keys = %w[proto port]
            json_arr.each do |i|
              # Check for mandatory keys
              missing_keys = mandatory_keys - i.keys
              unless missing_keys.empty?
                raise "The JSON value in ecv_map is missing mandatory keys: #{missing_keys.inspect}"
              end

              probe = {
                :listener_port => l[:iport],
                :name                => ['Probe', i['proto'], i['port'].to_s].join('-'),
                :protocol            => i['proto'],
                :port                => i['port'],
                :interval_in_seconds => i['interval_sec'] || interval_secs,
                :number_of_probes    => i['num_probes'] || num_probes,
                :default             => i['default'] || (json_arr.size == 1 ? true : false),
                :request_path        => i['req_path']
              }
              ecvs.push(probe)
            end
          else
            protocol = 'Tcp'
            req_path = nil
            if l[:iprotocol].upcase == 'HTTP'
              protocol = 'Http'
              req_path = the_probe.split(' ')[1]
            end

            ecvs.push(
              :listener_port       => l[:iport],
              :name                => ['Probe', protocol, l[:iport].to_s].join('-'),
              :interval_in_seconds => interval_secs,
              :number_of_probes    => num_probes,
              :port                => l[:iport],
              :protocol            => protocol,
              :request_path        => req_path
            )
          end
        else
          # Create a default "HTTP-GET /" probe for http listener,
          # tcp probe for everything else
          protocol = l[:iprotocol].upcase == 'HTTP' ? 'Http' : 'Tcp'
          req_path = l[:iprotocol].upcase == 'HTTP' ? '/' : nil
          ecvs.push(
            :listener_port       => l[:iport],
            :name                => ['Probe', protocol, l[:iport].to_s].join('-'),
            :interval_in_seconds => interval_secs,
            :number_of_probes    => num_probes,
            :port                => l[:iport].to_i,
            :protocol            => protocol,
            :request_path        => req_path
          )
        end #if the_probe
      end #listeners.each do |l|


      # Do not add probes not associated with any listeners, they're useless
=begin
      ecvs_raw.each_pair do |k,v|
        found = listeners.detect{ |l| l[:iport] == k }
        if !found
          ecvs.push(
            :listener_port       => k,
            :name                => ['NoListenerProbe', 'Tcp', k.to_s,].join('-'),
            :interval_in_seconds => interval_secs,
            :number_of_probes    => num_probes,
            :port                => k,
            :protocol            => 'Tcp',
            :request_path        => nil
          )
        end
      end
=end
      ecvs
    end

    def get_listeners_from_wo
      ci = {}
      ci = @node['workorder'].key?('rfcCi') ? @node['workorder']['rfcCi'] : @node['workorder']['ci']

      listeners = []

      if ci
        listeners_raw = ci['ciAttributes']['listeners']
        ciId = ci['ciId']

        listeners = []

        if listeners_raw
          listener_map = JSON.parse(listeners_raw)

          listener_map.each do |item|
            parts = item.split(' ')
            vproto = parts[0]
            vport = parts[1]
            iproto = parts[2]
            iport = parts[3]

            listen_name = "listener-#{ciId}_#{vproto}_#{vport}_#{iproto}_#{iport}"
            OOLog.info("Listener name: #{listen_name}")
            OOLog.info("Listener vprotocol: #{vproto}")
            OOLog.info("Listener vport: #{vport}")
            OOLog.info("Listener iprotocol: #{iproto}")
            OOLog.info("Listener iport: #{iport}")

            listener = {
                name: listen_name,
                iport: iport,
                vport: vport,
                vprotocol: vproto,
                iprotocol: iproto
            }

            listeners.push(listener)
          end
        end
        return listeners
      end

      listeners
    end

    def get_compute_nodes_from_wo
      compute_nodes = []
      computes = @node['workorder']['payLoad']['DependsOn'].select { |d| d[:ciClassName] =~ /Compute/ }
      if computes
        # Build computes nodes to load balance
        computes.each do |compute|
          compute_nodes.push(
              ciId: compute[:ciId],
              ipaddress: compute[:ciAttributes][:private_ip],
              hostname: compute[:ciAttributes][:hostname],
              instance_id: compute[:ciAttributes][:instance_id],
              instance_name: compute[:ciAttributes][:instance_name],
              allow_port: get_allow_rule_port(compute[:ciAttributes][:allow_rules])
          )
        end
      end
      compute_nodes
    end

    def get_allow_rule_port(allow_rules)
      port = 22 # Default port
      unless allow_rules.nil?
        rulesParts = allow_rules.split(' ')
        rulesParts.each do |item|
          port = item.gsub!(/\D/, '') if item =~ /\d/
        end
      end

      port
    end

    def validate_load_distribution_config
      ci_attribs = @node['workorder']['rfcCi']['ciAttributes']
      lb_method = ci_attribs['lbmethod']
      stickiness = ci_attribs['stickiness']
      persistence_type = ci_attribs['persistence_type']
      help_doc_link = 'http://oneops.com/user/design/lb-component.html'

      if (lb_method != 'roundrobin') && (lb_method != 'sourceiphash')
        OOLog.fatal("Bad LB configuration! #{lb_method} is not supported on azure. please look at #{help_doc_link} for supported load distribution methods on azure")
      end

      if stickiness == 'true'
        if persistence_type == 'cookieinsert'
          OOLog.fatal("Bad LB configuration! #{persistence_type} is not supported on azure. please look at #{help_doc_link} for supported load distribution methods on azure")
        end
      end
    end

    def get_lb_name
      platform_name = @node['workorder']['box']['ciName']
      plat_name = platform_name.gsub(/-/, '').downcase
      lb_name = "lb-#{plat_name}"

      lb_name
    end

    def get_azure_creds
      cloud_name = get_cloud_name
      app_type = get_app_type
      svc = get_service

      credentials = {
          tenant_id: svc['tenant_id'],
          client_secret: svc['client_secret'],
          client_id: svc['client_id'],
          subscription_id: svc['subscription']
      }
      credentials
    end


    def get_service
      cloud_name = get_cloud_name
      app_type = get_app_type
      svc = case app_type
              when 'lb'
                @node['workorder']['services']['lb'][cloud_name]['ciAttributes']
              when 'fqdn'
                @node['workorder']['services']['dns'][cloud_name]['ciAttributes']
              when 'storage'
                @node['workorder']['services']['storage'][cloud_name]['ciAttributes']
              else
                @node['workorder']['services']['compute'][cloud_name]['ciAttributes']
            end
    end

    def get_cloud_name
      cloud_name = @node['workorder']['cloud']['ciName']
    end

    def get_app_type
      @node['app_name']
    end

    def get_resource_group_name
      nsPathParts = get_ns_path_parts
      org = nsPathParts[1]
      assembly = nsPathParts[2]
      environment = nsPathParts[3]

      svc = get_service
      location = svc['location']

      new_cloud = Utils.is_new_cloud(@node)

      if new_cloud
        environment_ci_id = @node['workorder']['payLoad']['Environment'][0]['ciId']
        resource_group_name = org[0..15] + '-' + assembly[0..15] + '-' + environment_ci_id.to_s + '-' + environment[0..15] + '-' + Utils.abbreviate_location(location)
      else
        platform_ci_id = @node['workorder']['box']['ciId']
        resource_group_name = org[0..15] + '-' + assembly[0..15] + '-' + platform_ci_id.to_s + '-' + environment[0..15] + '-' + Utils.abbreviate_location(location)
      end

      resource_group_name
    end

    def get_ns_path_parts
      ci = get_ci
      nsPathParts = ci['nsPath'].split("/")
      nsPathParts
    end

    def get_ci
      rfcCi = @node['workorder']['ci']
      rfcCi
    end

    private :get_ecvs_from_wo, :get_listeners_from_wo, :get_compute_nodes_from_wo, :get_allow_rule_port, :validate_load_distribution_config
  end
end
