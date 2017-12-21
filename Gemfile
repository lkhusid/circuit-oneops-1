if ::File.exist?('/etc/oneops')
    config = {}
    ::File.read('/etc/oneops').split(/[, \n]+/).each do |line|
        key,value = line.split('=')
        config[key] = value
    end
    source "#{config['rubygems']}"
else
    `gem source`.split("\n").select{|l| (l =~ /^http/)}.each{|s| (source "#{s}")}
end

gem 'oneops-admin-adapter'
