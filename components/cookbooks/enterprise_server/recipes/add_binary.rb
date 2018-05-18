# Get the current node members and add to a variable
cluster_members = OneOpsHelper.get_nodes(node)
node.set['enterprise_server']['global']['cluster_members'] = "#{cluster_members}"
server_group = "#{node['enterprise_server']['global']['server_group']}"
server_user = "#{node['enterprise_server']['global']['server_user']}"
install_target_dir = "#{node.set['enterprise_server']['install_target_dir']}"
install_root_dir = "#{node['enterprise_server']['install_root_dir']}"
maven_identifier = node['enterprise_server']['maven_identifier']
install_from = node['enterprise_server']['install_from']
server_log_path = node['enterprise_server']['logs']['server_log_path']
catalina_logfile_path = "#{server_log_path}/catalina.out"
puts "#######################################################################"
puts " Install Base:   #{install_root_dir}"
puts " Install Target: #{install_target_dir}"
puts " From:           #{node["enterprise_server"]["install_from"]}"
puts " Runtime User:   #{server_user}"
puts " Runtime Group:  #{server_group}"
puts " Cluster Members:  #{cluster_members}"
puts " Cluster Members::  #{node["enterprise_server"]["global"]["cluster_members"]}"
puts "#######################################################################"

directory server_log_path do
  recursive true
  action :create
  ignore_failure true
  group server_group
  owner server_user
  not_if "test -d #{server_log_path}"
  mode '0755'
end

link node['enterprise_server']['server_log_path'] do
  to node['enterprise_server']['server_log_path']
  action :create
  ignore_failure true
  group server_group
  owner server_user
  mode '0755'
  not_if "test -d #{server_log_path}"
end

execute "touch #{catalina_logfile_path}" do
  not_if "test -d #{catalina_logfile_path}"
  returns [0,9]
end

file catalina_logfile_path do
  ignore_failure true
  group server_group
  owner server_user
  mode '0755'
end

directory install_target_dir do
  recursive true
  action :create
  ignore_failure true
  group server_group
  owner server_user
  not_if "test -d #{install_target_dir}"
  mode '0755'
end

remote_file "#{install_root_dir}/ent-serv.tgz" do
  owner server_user
  group server_group
  source MavenHelper.get_download_urls(install_from, maven_identifier)[0]
  action :create
end

tar_flags = node.workorder.rfcCi.rfcAction == 'update' ? '--exclude webapps/ROOT' : ''
bash 'extract' do
  cwd install_root_dir
  code <<-EOF
    tar -zxf ${tar_flags} ent-serv.tgz -C #{install_target_dir}
    rm ent-serv.tgz
    chown -R #{server_user}:#{server_group} #{install_target_dir}
  EOF
  returns 0
end

bash 'perms_change' do
  cwd install_target_dir
  code <<-EOF
    chmod 770 bin/*.sh
  EOF
end
