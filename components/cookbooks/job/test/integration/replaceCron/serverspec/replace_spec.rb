require 'spec_helper'

describe user('vagrant') do
  it { should exist }
end

describe command('crontab -l') do
  its(:stdout) { should contain('SHELL=/var/') }
end

describe cron do
  it { should have_entry "#{$node['workorder']['rfcCi']['ciAttributes']['minute']} #{$node['workorder']['rfcCi']['ciAttributes']['hour']} #{$node['workorder']['rfcCi']['ciAttributes']['day']} #{$node['workorder']['rfcCi']['ciAttributes']['month']} #{$node['workorder']['rfcCi']['ciAttributes']['weekday']} #{$node['workorder']['rfcCi']['ciAttributes']['cmd']}" }
end

describe file('/var/log/cron') do
  it { should be_file }
end