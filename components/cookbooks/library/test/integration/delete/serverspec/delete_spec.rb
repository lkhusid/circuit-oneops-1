require 'spec_helper'

describe package(JSON.parse($node['workorder']['rfcCi']['ciAttributes']['packages'])[0]) do
  it { should_not be_installed }
end

describe package(JSON.parse($node['workorder']['rfcCi']['ciAttributes']['packages'])[1]) do
  it { should_not be_installed }
end

describe package(JSON.parse($node['workorder']['rfcCi']['ciAttributes']['packages'])[2]) do
  it { should_not be_installed }
end
