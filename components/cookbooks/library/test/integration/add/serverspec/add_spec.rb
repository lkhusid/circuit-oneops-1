is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

packages = JSON.parse($node['workorder']['rfcCi']['ciAttributes']['packages'])

packages.each do |pack|
  describe package(pack) do
    it { should be_installed }
  end
end