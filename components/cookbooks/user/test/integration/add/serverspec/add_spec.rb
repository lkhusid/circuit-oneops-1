
require 'spec_helper'

describe user($node['user']['username']) do
  it { should exist }
end

describe user($node['user']['username']) do
  it { should belong_to_group $node['user']['group'] }
end

describe user($node['user']['username']) do
  it { should have_home_directory "/home/#{$node['user']['username']}" }
end

describe user($node['user']['username']) do
  it { should have_login_shell $node['user']['login_shell'] }
end
