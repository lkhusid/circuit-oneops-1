require 'spec_helper'

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_file }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should exist }
end

describe file(File.dirname($node['workorder']['rfcCi']['ciAttributes']['path'])) do
  it { should be_directory }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should contain $node['workorder']['rfcCi']['ciAttributes']['content'] }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_mode 755 }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_owned_by 'root' }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_grouped_into 'root' }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_readable }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should contain $node['workorder']['rfcCi']['ciAttributes']['content'] }
end
