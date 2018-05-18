is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

is_windows = ENV['OS']=='Windows_NT' ? true : false
source = $node['workorder']['rfcCi']['ciAttributes']['source']

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should exist }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_file }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_owned_by 'root' }
end

describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
  it { should be_grouped_into 'root' }
end

if !is_windows
  context "URL is accessible" do
    it "should exist" do
      result = `curl -I #{source}`
      expect(result).to include('200 OK')
    end
  end
end


if !is_windows
  context "file size" do
    describe file($node['workorder']['rfcCi']['ciAttributes']['path']) do
      result = `curl -I #{source}`
      entries = result.split(/\n/)
      entries.each do |info|
        if info =~ /Content-Length/
          size = info.split(':').last.strip.to_i
          its(:size) { should == size }
        end
      end
    end
  end
end


if !is_windows
  result = `curl -I #{source}`
  entries = result.split(/\n/)
  entries.each do |info|
    if info =~ /ETag/
      tag = info.split(':').last
      if tag =~ /SHA1/
        sha1 = tag.split('{').last.split('}').first
        comm = "sha1sum #{$node['workorder']['rfcCi']['ciAttributes']['path']}"
        describe command(comm) do
          its(:stdout) { should contain(sha1) }
        end
      end
    end
  end
end