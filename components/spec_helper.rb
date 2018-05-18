require 'serverspec'
require 'pathname'
require 'json'

$node_wo = ::JSON.parse(File.read(ENV['WORKORDER'].to_s)) if ENV['WORKORDER']

if ENV['OS'] == 'Windows_NT'
  set :backend, :cmd
  # On Windows, set the target host's OS explicitly
  set :os, :family => 'windows'
  $node_wo ||= ::JSON.parse(File.read('c:\windows\temp\serverspec\node.json'))
else
  set :backend, :exec
  $node_wo ||= ::JSON.parse(File.read('/tmp/serverspec/node.json'))
end

#Renaming ci attribute (AO) to rfcCi (WO), so when testing Action Orders we can re-use tests cases written for Work Orders
$node_wo['workorder']['rfcCi'] = $node_wo['workorder'].delete('ci') if $node_wo['workorder'].has_key?('ci')


custom_ruby_bindir = '/home/oneops/ruby/2.0.0-p648/bin'
if os[:family] != 'windows' && File.exist?("#{custom_ruby_bindir}/chef-solo")
  set :path, "#{custom_ruby_bindir}:/sbin:/usr/local/sbin:/usr/sbin:$PATH"
else
  set :path, '/sbin:/usr/local/sbin:/usr/sbin:$PATH' unless os[:family] == 'windows'
end

require 'chef'

#Create node object, add attributes from WO and Ohai
$node = Chef::Node.new()
ohai = Ohai::System.new()
filter = %w{fqdn machinename hostname platform platform_version os os_version}
ohai.all_plugins(filter)
$node.consume_external_attrs(ohai.data, $node_wo)
