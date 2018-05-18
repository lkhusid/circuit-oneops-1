require 'spec_helper'

describe command('node -v') do
	its(:stdout) { should contain($node['workorder']['rfcCi']['ciAttributes']['version']) }
end

describe command('npm -v') do
	#its(:stdout) { should match /3.10.10/ }
	its(:stdout) { should contain($node['workorder']['rfcCi']['ciAttributes']['npm']) }
end
