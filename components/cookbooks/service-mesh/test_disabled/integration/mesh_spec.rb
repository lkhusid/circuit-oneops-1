is_windows = ENV['OS']=='Windows_NT' ? true : false
$circuit_path = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{$circuit_path}/circuit-oneops-1/components/spec_helper.rb"

mesh_dir =  $node['workorder']['rfcCi']['ciAttributes']['service-mesh-root']
describe file(mesh_dir) do
  it { should be_directory }
end

status_check = '/etc/init.d/servicemesh status'
describe command(status_check) do
  its(:stdout) { should contain('service-mesh is running') }
end

admin_port = 9990
describe port(admin_port) do
  it { should be_listening }
end

ingress_port = 4141
describe port(ingress_port) do
  it { should be_listening }
end

linkerd_conf =  "#{mesh_dir}/linkerd-sr.yaml"
describe file(linkerd_conf) do
  it { should be_file }
  it { should exist }
end
