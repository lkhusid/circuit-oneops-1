# Helper functions for network recipe
module NetworkHelper
  NAMESERVER_CMD = "cat /etc/resolv.conf |grep -v 127 | grep -v '^#' " \
                   "| grep nameserver | awk '{print $2}'".freeze

  def get_nameservers
    Mixlib::ShellOut.new(NAMESERVER_CMD).run_command.
    stdout.split("\n").join(';')
  end

  def authoritative_dns(zone_domain)
    cmd = "dig +short NS #{zone_domain}"
    Mixlib::ShellOut.new(cmd).run_command.stdout.tr("\n", ' ').strip
  end

  def authoritative_dns_ip(zone_domain)
    cmd = "dig +short #{authoritative_dns(zone_domain)}"
    Mixlib::ShellOut.new(cmd).run_command.stdout.tr("\n", ';').strip
  end

  def trim_zone_domain(zone_domain)
    parts = zone_domain.downcase.split('.')

    while parts.size > 2 && authoritative_dns(parts.join('.')).empty?
      parts = parts.last(parts.size - 1)
    end
    parts.join('.')
  end

  def trim_customer_domain(node)
    customer_domain = node['customer_domain']
    customer_domain =~ /^\./ ? customer_domain.slice(0) : customer_domain
  end

  # Generates 2 lists of search domains - using additional_search_domains
  # attribute from OS component + customer domain
  # First list is comma-separated
  # Second list is space separated with each domain ending with dot
  #
  # @param  : chef node object
  # @return : string comma-separated list of search domains
  #           string space-separated list of search domains (ending with dot)
  #
  def search_domains(node)
    attr = 'additional_search_domains'.freeze
    ciAttr = node['workorder']['rfcCi']['ciAttributes']
    domains_arr = []
    if ciAttr.key?(attr) && !ciAttr[attr].empty?
      domains_arr.concat(JSON.parse(ciAttr[attr]))
    end
    domains_arr.push(trim_customer_domain(node))

    [domains_arr.map{|i| '"' + i + '"'}.join(',').downcase,
     domains_arr.map { |i| i + '.' }.join(' ').downcase]
  end
end
