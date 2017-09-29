require 'spec_helper'

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should_not be_file }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should_not exist }
end
