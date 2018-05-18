require "/home/oneops/circuit-oneops-1/components/spec_helper.rb"


if $node['java']['flavor'] == 'oracle'
  describe file('/etc/profile.d/java.sh') do
    it { should_not exist }
  end
end