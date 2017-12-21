is_windows = ENV['OS'] == 'Windows_NT'
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"

OBJECTSTORE_EXE_FILE   = '/usr/local/bin/objectstore'.freeze
OBJECTSTORE_CREDS_FILE = '/etc/objectstore_creds.json'.freeze

TEST_CONTAINER_NAME    = 'objectstore-test-container'.freeze
TEST_BLOB_NAME         = 'test-blob'.freeze
TEST_BLOB_SIZE         = '10M'.freeze

describe file(OBJECTSTORE_EXE_FILE) do
  it { should exist }
end

describe file(OBJECTSTORE_EXE_FILE) do
  it { should be_executable }
end

describe file(OBJECTSTORE_CREDS_FILE) do
  it { should exist }
end

describe command("fallocate -l #{TEST_BLOB_SIZE} #{TEST_BLOB_NAME}") do
  its(:exit_status) { should eq 0 }
end

describe command("objectstore upload #{TEST_BLOB_NAME} #{TEST_CONTAINER_NAME}") do
  its(:exit_status) { should eq 0 }
end

describe command("objectstore download #{TEST_CONTAINER_NAME}/#{TEST_BLOB_NAME} ./") do
  its(:exit_status) { should eq 0 }
end

describe command("objectstore delete #{TEST_CONTAINER_NAME}") do
  its(:exit_status) { should eq 0 }
end

describe command("rm -f #{TEST_BLOB_NAME}") do
  its(:exit_status) { should eq 0 }
end
