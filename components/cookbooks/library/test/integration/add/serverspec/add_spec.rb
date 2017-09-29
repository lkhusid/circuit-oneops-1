require 'spec_helper'

describe package(JSON.parse($node['workorder']['rfcCi']['ciAttributes']['packages'])[0]) do
  it { should be_installed }
end

describe package(JSON.parse($node['workorder']['rfcCi']['ciAttributes']['packages'])[1]) do
  it { should be_installed }
end

describe package(JSON.parse($node['workorder']['rfcCi']['ciAttributes']['packages'])[2].scan('ruby')[0]) do
  its('version') { should eq JSON.parse($node['workorder']['rfcCi']['ciAttributes']['packages'])[2].gsub('ruby-', '') }
end
