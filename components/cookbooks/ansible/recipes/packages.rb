

%w(python-devel libffi-devel openssl-devel git gcc).each do |p|
  package p do
  	Chef::Log.info("Installing package #{p}")
    action :install
  end
end
