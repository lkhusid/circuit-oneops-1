is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

ci = nil
# work order
if $node["workorder"].has_key?("rfcCi")
  ci = $node['workorder']['rfcCi']
# action order
elsif $node["workorder"].has_key?("ci")
  ci = $node['workorder']['ci']
end

describe package('git') do
  it { should be_installed }
end


if ci['ciAttributes']['scm'] == "git"

  manifest = $node['workorder']['payLoad']['RealizedAs'].first['ciName']
  install_dir = ($node["build"].has_key?("install_dir") && !$node['build']['install_dir'].empty?) ? $node['build']['install_dir'] : "/opt/#{manifest}"
  describe file(install_dir) do
    it { should be_directory }
  end

  as_user = ($node['build'].has_key?('as_user') && !$node['build']['as_user'].empty?) ? $node['build']['as_user'] : "root"
  as_group = ($node['build'].has_key?('as_group') && !$node['build']['as_group'].empty?) ? $node['build']['as_group'] : "root"

  describe user(as_user) do
    it { should exist }
  end

  describe user(as_user) do
    it { should belong_to_group as_group }
  end

  describe file(install_dir) do
    it { should be_owned_by as_user }
  end

  describe file(install_dir) do
    it { should be_grouped_into as_group }
  end

  revision = $node['workorder']['rfcCi']['ciAttributes']['revision']
  comm = "cd "+install_dir+"/current; git branch"
  describe command(comm) do
    its(:stdout) { should match /#{revision}/ }
  end

  continuous_integration = $node['workorder']['rfcCi']['ciAttributes']['ci'] == "true" ? true : false
  if continuous_integration
    describe cron do
      ciName = $node['workorder']['rfcCi']['ciName']
      entry = "0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/bin/chef-solo -l info -F doc -c /home/oneops/circuit-oneops-1/components/cookbooks/chef-build.#{ciName}.rb -j /opt/oneops/build.#{ciName}.json >> /tmp/build.#{ciName}.log 2>&1"
      it { should have_entry entry }
    end
  end

  if !ci['ciAttributes']['migration_command'].empty?
    migration_file = "#{install_dir}/build.sh"
    describe file(migration_file) do
      it { should be_file }
    end

    comm = "cat #{migration_file}"
    describe command(comm) do
      its(:stdout) { should match /#{ci['ciAttributes']['migration_command']}/ }
    end

  end
end