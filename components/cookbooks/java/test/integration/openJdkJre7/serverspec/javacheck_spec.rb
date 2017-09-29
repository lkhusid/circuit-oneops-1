require 'spec_helper'

describe command('java -version 2>&1 | grep OpenJDK') do
  its(:exit_status) { should eq 0 }
end
describe command('java -version 2>&1 | grep 1.7') do
  its(:exit_status) { should eq 0 }
end
describe file($node['java']['install_dir']) do
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
end