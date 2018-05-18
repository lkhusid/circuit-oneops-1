is_windows = ENV['OS'] == 'Windows_NT'
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/cookbooks/service-mesh/test/integration/mesh_spec.rb"
