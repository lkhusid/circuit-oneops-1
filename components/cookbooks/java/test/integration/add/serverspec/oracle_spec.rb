#
# Basic verification that java was installed properly
#

require "/home/oneops/circuit-oneops-1/components/spec_helper.rb"


if $node['java']['flavor'] == 'oracle'
  javaVersion = "1.#{$node['java']['version']}.0"
  javaUVersion = javaVersion + "_#{$node['java']['uversion']}"

  # java_home env variable
  describe command('echo $JAVA_HOME | grep java') do
    its(:exit_status) { should eq 0 }
  end

  # version
  if !$node['java']['uversion'].nil? && !$node['java']['uversion'].empty?
    describe command('java -version') do
      its(:stderr) { should match /#{javaUVersion}/ }
      its(:exit_status) { should eq 0 }
    end
  else
    describe command('java -version') do
      its(:stderr) { should match /#{javaVersion}/ }
      its(:exit_status) { should eq 0 }
    end
  end

  # install directory
  describe file($node['java']['install_dir']) do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe file('/etc/profile.d/java.sh') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should contain '/usr/java/default' }
  end

  describe file('/usr/java/default') do
    it { should be_symlink }
  end

  if $node['java']['jrejdk'] == 'jdk'
    describe file('/usr/java/default/jre') do
      it { should exist }
    end
  else
    describe file('/usr/java/default/jre') do
      it { should_not exist }
    end
  end
end