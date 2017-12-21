require 'spec_helper'

install_dir = ($node["build"].has_key?("install_dir") && !$node['build']['install_dir'].empty?) ? $node['build']['install_dir'] : "/opt/#{manifest}"
comm = "ls #{install_dir}/current"
describe command(comm) do
  its(:stderr) { should match /No such file or directory/ }
end