is_windows = ENV['OS'] == 'Windows_NT'
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"

if !is_windows
  if $node['java']['flavor'] == 'oracle'
    require '/home/oneops/circuit-oneops-1/components/cookbooks/java/test/integration/delete/serverspec/oracle.rb'
  else
    puts "------- no java tests for java flavor #{$node['java']['flavor']} -------"
  end
else
  puts "------- no java tests for ostype windows -------"
end