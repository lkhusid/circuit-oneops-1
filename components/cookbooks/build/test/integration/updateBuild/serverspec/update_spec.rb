require 'spec_helper'

describe package('git') do
  it { should be_installed }
end

describe command('cd /opt/build/current; git branch') do
  its(:stdout) { should match /#{$node['workorder']['rfcCi']['ciAttributes']['revision']}/ }
end