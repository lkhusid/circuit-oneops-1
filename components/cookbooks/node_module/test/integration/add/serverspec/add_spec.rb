is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

log_file = $node['workorder']['rfcCi']['ciAttributes']['log_file']
if !log_file.nil? && !log_file.empty?
  describe file(log_file) do
    it { should be_file }
  end
end

script_location = $node['workorder']['rfcCi']['ciAttributes']['script_location']
if !script_location.nil? && !script_location.empty?
  script = script_location.split(" ")[0]
  describe file(script) do
    it { should be_file }
  end
end

app_server_loc = $node['workorder']['rfcCi']['ciAttributes']['server_root']
if !app_server_loc.nil? && !app_server_loc.empty?
  describe file(app_server_loc) do
    it { should be_directory }
  end
end

file = "/etc/init.d/nodejs"
describe file(file) do
  it { should be_executable }
end

describe service('nodejs') do
  it { should be_enabled }
end

describe service('nodejs') do
  it { should be_running }
end

user = $node['workorder']['rfcCi']['ciAttributes']['as_user']
if !user.nil? && !user.empty?
  describe user(user) do
    it { should exist }
  end
end