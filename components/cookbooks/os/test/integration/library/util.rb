# Testing library

# Matches a string to a regex template
#
# @param  : regex template
#           string file content
# @return : boolean match?
#           string first captured group
#           string second captured group
#
def match_regex(rgx, data)
  result = rgx.match(data)
  if result
    return true, result[1], result[2]
  else
    return false, nil, nil
  end
end

# Compares content of named.conf.options file to the template
#
# @param  : string file content
# @return : boolean match?
#           string forwarder ips (semicolon-separated)
#
def compare_named_conf_options(data)
  rgx = /options {
  directory "\/var\/cache\/bind";
  auth-nxdomain no;    \# conform to RFC1035
  listen-on-v6 { any; };
  forward only;
  forwarders { (\S+) };
};/
  match_regex(rgx, data)
end

# Compares content of named.conf.local file to the template
#
# @param  : string file content
# @return : boolean match?
#           string domain_zone
#           string forwarder ips (semicolon-separated)
#
def compare_named_conf_local(data)
  rgx = /zone "(\S+\.)\1*" IN {
    type forward;
    forwarders {(\S+)};
};/
  match_regex(rgx, data)
end

# Compares content of /etc/dhcp/dhclient.conf file to the template
#
# @param  : string file content
# @return : boolean match?
#           string customer domains (comma-separated)
#           string hostname
#
def compare_dhclient_conf(data)
  rgx = /supersede domain-search (\S+);
send host-name "(\S+)";/
  match_regex(rgx, data)
end
