require 'spec_helper'

describe command('crontab -l') do
  its(:stdout) { should contain('') }
end

describe cron do
  it { should have_entry '' }
end
