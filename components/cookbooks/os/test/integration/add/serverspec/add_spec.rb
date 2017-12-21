# unable to put this test in compute so it is going here. It tests adding gem proxy to oneops user when install_base.sh
# adds them for root.
require 'spec_helper'

root_gem_source = `gem source | grep -m 1 "http"`
describe user("oneops") do
  it { should exist }
end

describe command('su - oneops -c "gem source" | grep -m 1 "http"') do
  its(:stdout) { should eq root_gem_source}
end
