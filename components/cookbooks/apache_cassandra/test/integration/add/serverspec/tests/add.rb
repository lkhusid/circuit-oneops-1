describe user('cassandra') do
    it { should exist }
end

describe service('cassandra') do
    it { should be_enabled }
    it { should be_running }
end

#%w{7000 7001 9160 9042 7199}.each do |p|
#    describe port(p) do
#        it { should be_listening }
#    end
#end

#describe command('/opt/cassandra/bin/nodetool netstats') do
#    its(:stdout) { should match /NORMAL/}
#end
