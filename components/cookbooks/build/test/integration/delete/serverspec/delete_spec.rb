is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

manifest = $node['workorder']['payLoad']['RealizedAs'].first['ciName']
install_dir = ($node["build"].has_key?("install_dir") && !$node['build']['install_dir'].empty?) ? $node['build']['install_dir'] : "/opt/#{manifest}"
comm = "ls #{install_dir}/current"
describe command(comm) do
  its(:stderr) { should match /No such file or directory/ }
end