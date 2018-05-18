is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

ci = nil
if $node['workorder'].has_key?("rfcCi")
  ci = $node['workorder']['rfcCi']
elsif $node['workorder'].has_key?("ci")
  ci = $node['workorder']['ci']
end

usr = ci['ciAttributes']['user']
vars = JSON.parse(ci['ciAttributes']['variables']) || {}

describe user(usr) do
  it { should exist }
end

describe cron do
  it { should have_entry("#{$node['workorder']['rfcCi']['ciAttributes']['minute']} #{$node['workorder']['rfcCi']['ciAttributes']['hour']} #{$node['workorder']['rfcCi']['ciAttributes']['day']} #{$node['workorder']['rfcCi']['ciAttributes']['month']} #{$node['workorder']['rfcCi']['ciAttributes']['weekday']} #{$node['workorder']['rfcCi']['ciAttributes']['cmd']}").with_user(usr) }
end

describe file('/var/log/cron') do
  it { should be_file }
end

if usr == "root"
  describe command('crontab -l') do
    its(:stdout) { should contain("HOME=#{vars['HOME']}") if vars.has_key?('HOME') && !vars['HOME'].empty? }
    its(:stdout) { should contain("SHELL=#{vars['SHELL']}") if vars.has_key?('SHELL') && !vars['SHELL'].empty? }
    its(:stdout) { should contain("MAILTO=#{vars['MAILTO']}") if vars.has_key?('MAILTO') && !vars['MAILTO'].empty? }
    its(:stdout) { should contain("PATH=#{vars['PATH']}") if vars.has_key?('PATH') && !vars['PATH'].empty? }
  end
end