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

describe cron do
  it { should_not have_entry("#{$node['workorder']['rfcCi']['ciAttributes']['minute']} #{$node['workorder']['rfcCi']['ciAttributes']['hour']} #{$node['workorder']['rfcCi']['ciAttributes']['day']} #{$node['workorder']['rfcCi']['ciAttributes']['month']} #{$node['workorder']['rfcCi']['ciAttributes']['weekday']} #{$node['workorder']['rfcCi']['ciAttributes']['cmd']}").with_user(usr) }
end