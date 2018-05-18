is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

service_name = $node['workorder']['rfcCi']['ciAttributes']['service_name']

initService = "/etc/init.d/#{service_name}"
systemdService = "/usr/lib/systemd/system/#{service_name}.service"

service_type = nil
if File.exist?(systemdService)
  service_type = "systemd"
elsif File.exist?(initService)
  service_type = "init"
end

if service_type == "systemd"
  describe service(service_name) do
    it { should be_running }
  end
end


if service_type == "init"
  file = "/etc/init.d/#{service_name}"
  describe file(file) do
    it { should be_executable }
  end
end
