
require 'spec_helper'

describe user($node['user']['username']) do
  it { should_not exist }
end

describe user($node['user']['username']) do
  it { should_not belong_to_group $node['user']['group'] }
end

describe group($node['user']['group']) do
  it { should_not exist }
end
