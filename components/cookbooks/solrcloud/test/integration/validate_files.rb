is_windows = ENV['OS']=='Windows_NT' ? true : false
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"

require 'json'
require 'nokogiri'

# Validate xml file for syntax error, if any
def validate_xml(xml_file)
  begin
    xml = File.read(xml_file)
    doc = Nokogiri::XML(xml) { |config| config.strict }
  rescue Nokogiri::XML::SyntaxError => e
    raise "caught exception in file #{xml_file} : #{e}"
  end
end

# Execute the given command, raise error if command was failed, otherwise return command output as array of lines
def execute_command(cmd)
  puts "executing command #{cmd}"
  result = `#{cmd}`
  if $? != 0
    raise "Error while executing command #{cmd} => #{result}"
  end
  puts "command output = #{result}"
  return result.split("\n")
end

# Get search the files by regex.
# If multiple_allowed = false and multiple files found, throw error
def get_file_path(regex_path, multiple_allowed=false)
  files = execute_command("find #{regex_path}")
  if files.size == 0
    raise "No file found matching pattern #{regex_path}"
  elsif !multiple_allowed && files.size > 1
    raise "Expected a single file but #{files.size} files found matching pattern #{regex_path}"
    raise "#{files.size} files found matching pattern #{regex_path} but we expected only one. Files found = #{files.to_json}"
  end
  return multiple_allowed ? files : files[0]
end

# Execute the monitor script and verify that the monitor status is euqal to expected status
def validate_monitor_status(monitor_path, args, expected_status)
  cmd = "#{monitor_path} #{args.join(' ')}"
  result = execute_command(cmd)
  actual_status = nil
  result.each do |s|
    if s.include?("up=")
      actual_status = s.split("up=")[1].to_i
    end
  end 
  if actual_status != expected_status
    raise "For command #{cmd} actual status #{actual_status} does not match with expected status #{expected_status}"
  end
end

# Validate propery file
# For each line from the file, split the line by '=' to verify that it has property name and property value
# Property value can be null or empty but property name must be valid string
def validate_property_file(file_path)
  result = File.read(file_path).split("\n")
  result.each do |prop_string|
    prop_string.strip!
    next if prop_string.empty? || prop_string.start_with?("#")
    prop = prop_string.split("=")
    if prop.size == 0 || prop.size > 2
      raise "Invalid property #{prop_string} in file #{file_path}"
    elsif prop[0] == nil || prop[0].strip.empty?
      raise "Invalid property name for #{prop_string} in file #{file_path}"
    end
  end
end

port = $node['solrcloud']['port_no']
jolokia_port = $node['solrcloud']['jolokia_port']

puts "solr port = #{port}"
puts "jolokia_port = #{jolokia_port}"
# validate solr service 
service_file = get_file_path('/etc/init.d/solr[0-9]*')
puts "solr service file = #{service_file}"

# Validate check_solrprocess monitor
solr_monitor_file = get_file_path('/opt/nagios/libexec/check_solrprocess.sh')
puts "solr_monitor_file = #{solr_monitor_file}"
validate_monitor_status(solr_monitor_file, [port], 100)

# Validate check_solr_mbeanstat monitor
solr_mbeanstat_file = get_file_path('/opt/nagios/libexec/check_solr_mbeanstat.rb')
execute_command("#{solr_mbeanstat_file} MemoryStats #{port}")
execute_command("#{solr_mbeanstat_file} ReplicaStatus #{port}")
execute_command("#{solr_mbeanstat_file} JVMThreadCount #{jolokia_port}")
execute_command("#{solr_mbeanstat_file} HeapMemoryUsage #{jolokia_port}")

# Validate check_solr_mbeanstat monitor
solr_monitor_folder = "/opt/solr/solrmonitor"
solr_monitor_script = "metrics-tool.rb"
solr_monitor_file = get_file_path("#{solr_monitor_folder}/#{solr_monitor_script}")
execute_command("cd /opt/solr/solrmonitor; ruby metrics-tool.rb")
get_file_path("/opt/solr/log/medusa_stats.log")
get_file_path("/opt/solr/log/jmx_medusa_stats.log")

# Validate check_solr_zk_conn monitor
zk_monitor_file = get_file_path('/opt/nagios/libexec/check_solr_zk_conn.sh')
validate_monitor_status(zk_monitor_file, [], 100)

# Validate log4j.properties monitor
log4j_property_files = get_file_path('/app/solrdata*/ -name log4j.properties', true)
puts "log4j_property_files = #{log4j_property_files}"
log4j_property_files.each do |file|
  validate_property_file(file)
end

# Validate solrconfig.xml monitor
xml_files = get_file_path('/app/solr[0-9]*/server/solr -name solr*.xml | grep -v /configsets/', true)
xml_files.each do |file|
  puts "Validating xml file :  #{file}"
  validate_xml(file)
end
