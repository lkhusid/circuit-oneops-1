require 'spec_helper'

describe command('ls /opt/build/current') do
  its(:stderr) { should match /No such file or directory/ }
end