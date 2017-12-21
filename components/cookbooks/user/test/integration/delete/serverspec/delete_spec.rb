
require 'spec_helper'

describe user($node['user']['username']) do
  it { should_not exist }
end

if !$node['user']['username'].to_s.empty? && !$node['user']['group'].eql?('[]')
	describe user($node['user']['username']) do
	  it { should_not belong_to_group $node['user']['group'] }
	end

	describe group($node['user']['group']) do
	  it { should_not exist }
	end
end