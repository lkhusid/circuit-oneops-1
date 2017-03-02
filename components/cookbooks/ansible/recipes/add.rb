
#install pip if not already installed
easy_install_package 'pip' do
	action :install
end

%w(python-devel openssl-devel git).each do |p|
	package p do
		action :install
	end
end

version = node.workorder.rfcCi.ciAttributes.ansible_version

ansible_pip "ansible" do
	version version
	action :install
end

# create ansible roles directory
directory "/etc/ansible/roles" do
	recursive true
	action :create
end

template "/etc/ansible/hosts" do
	source "hosts.erb"
end

puts "***RESULT:ansible_version=#{version}"