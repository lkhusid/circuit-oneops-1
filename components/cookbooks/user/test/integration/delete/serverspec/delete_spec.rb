is_windows = ENV['OS']=='Windows_NT' ? true : false
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"

user = $node['user']['username'].gsub('\\','\\\\\\')
group = JSON.parse($node['user']['group'])

describe user(user) do
  it { should_not exist }
end unless user.include?('\\') #Can not correctly check domain user existence for users in a different domain

if is_windows
  group.push('Administrators') unless group.include?('Administrators')
  group.each do |g|
    describe command("& {net localgroup #{g} } | select-string -pattern '^#{user}$'") do
      its(:stdout) { should be_empty  }
    end
  end
else
  describe group(user) do
    it { should_not exist }
  end

  group.each do |g|
    describe user(user) do
      it { should_not belong_to_group g }
    end
  end
end
