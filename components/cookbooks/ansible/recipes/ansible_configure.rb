
directory '/etc/ansible/roles' do
	recursive true
end

file '/etc/ansible/hosts' do 
	content 'localhost ansible_connection=local'
end

directory '/etc/ansible/script' do
	recursive true
end

cookbook_file "/etc/ansible/script/load_role.py" do
	source "load_role.py"
end

cookbook_file "/etc/ansible/script/get-pip.py" do
	source "get-pip.py"
end
