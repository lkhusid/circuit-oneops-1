is_windows = ENV['OS'] == 'Windows_NT'
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"

ostype = $node['workorder']['rfcCi']['ciAttributes']['ostype']
case ostype
  when /centos-7/i, /redhat-7/i
    require "/home/oneops/circuit-oneops-1/components/cookbooks/os/test/integration/add/serverspec/centos_redhat_7.rb"
  else
    puts "no tests for ostype #{ostype}"
end
