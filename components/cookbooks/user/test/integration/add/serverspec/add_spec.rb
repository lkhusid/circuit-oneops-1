
require 'spec_helper'

describe user($node['user']['username']) do
  it { should exist }
  it { should have_login_shell $node['user']['login_shell'] }
  it { should have_home_directory "#{$node['user']['home_directory']}" }
end

if !$node['user']['username'].to_s.empty? && !$node['user']['group'].eql?('[]')
  describe user($node['user']['username']) do
    it { should belong_to_group $node['user']['group'] }
  end
end