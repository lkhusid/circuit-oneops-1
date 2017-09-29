require 'serverspec'
require 'pathname'
require 'json'

describe cron do
  it { should have_entry "0,5,10,15,20,25,30,35,40,45,50,55 * * * * /usr/local/bin/chef-solo -l info -F doc -c /home/oneops/circuit-oneops-1/components/cookbooks/chef-build.dummy.rb -j /opt/oneops/build.dummy.json >> /tmp/build.dummy.log 2>&1" }
end