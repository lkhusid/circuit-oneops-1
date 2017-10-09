require 'spec_helper'

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_file }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should exist }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_owned_by 'root' }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_grouped_into 'root' }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']+'.tmp') do
  it { should be_mode 644 }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  its(:md5sum) { should eq 'c81469fdc4e681af3d7438b533d0f7ab' }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  its(:size) { should == 2225399 }
end