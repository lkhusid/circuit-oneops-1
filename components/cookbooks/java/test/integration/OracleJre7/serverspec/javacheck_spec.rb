require 'spec_helper'

describe command('echo $JAVA_HOME | grep java') do
  its(:exit_status) { should eq 0 }
end

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
end