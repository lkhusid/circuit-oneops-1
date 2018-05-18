is_windows = ENV['OS'] == 'Windows_NT'
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"

describe file('/usr/local/bin/objectstore') do
  it { should_not exist }
end

describe file('/etc/objectstore_config.json') do
  it { should_not exist }
end
