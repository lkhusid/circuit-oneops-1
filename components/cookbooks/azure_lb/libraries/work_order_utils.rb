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
      ci_attribs = @node['workorder']['rfcCi']['ciAttributes']
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
      validate_ecvs_and_listeners_config
      validate_load_distribution_config
    end

    def get_ecvs_from_wo
      ci = {}
      ci = @node['workorder'].key?('rfcCi') ? @node['workorder']['rfcCi'] : @node['workorder']['ci']

      ecvs = []
      ecvs_raw = JSON.parse(ci['ciAttributes']['ecv_map'])
      if ecvs_raw && listeners
        interval_secs = 15
        num_probes = 3

        ecvs_raw.each do |item|
          # each item is an array
          port = item[0].to_i
          pathParts = item[1].split(' ')
          request_path = pathParts[1]

          probe_name = "Probe#{port}"

          the_listener = nil
          listeners.each do |listener|
            listen_port = listener[:iport].to_i
            if listen_port == port
              the_listener = listener
              break
            end
          end

          if the_listener && (the_listener[:iprotocol].upcase == 'TCP' || the_listener[:iprotocol].upcase == 'HTTPS')
            protocol = 'Tcp'
            request_path = nil # If Protocol is set to TCP, this value MUST BE NULL.
          else
            protocol = 'Http'
          end

          ecvs.push(
              probe_name: probe_name,
              interval_secs: interval_secs,
              num_probes: num_probes,
              port: port,
              protocol: protocol,
              request_path: request_path
          )
        end

        #if a listener, with Tcp or https as backend protocol, doesn't have a matching ecv then create a new Tcp ecv for it
        listeners.each do |l|
          has_ecv = ecvs.any? {|ecv| ecv[:port].to_i == l[:iport].to_i}
          if !has_ecv && (l[:iprotocol].upcase == 'TCP' || l[:iprotocol].upcase == 'HTTPS')
            ecvs.push(
                probe_name: "Probe#{l[:iport]}",
                interval_secs: interval_secs,
                num_probes: num_probes,
                port: l[:iport].to_i,
                protocol: 'Tcp',
                request_path: nil
            )
          end
        end

      end

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

    def validate_ecvs_and_listeners_config
      http_listener_exists = listeners.any? {|l| l[:iprotocol].upcase == 'HTTP'}

      if http_listener_exists
        http_ecv_exists = ecvs.any? {|e| e[:protocol].upcase == 'HTTP'}
        OOLog.fatal('Bad LB configuration! at least one http ecv should be present when there is a http listener') unless http_ecv_exists
      end
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

    private :get_ecvs_from_wo, :get_listeners_from_wo, :get_compute_nodes_from_wo, :get_allow_rule_port, :validate_ecvs_and_listeners_config, :validate_load_distribution_config
  end
end