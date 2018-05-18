# make compute cloud service env_vars available on the system for subsequent workorders
ostype = node[:workorder][:rfcCi][:ciAttributes][:ostype]
prefix = get_prefix(ostype)
env_vars_content = get_cloud_env_vars_content(node)
oo_vars_content = get_oo_vars_content(node)
oo_vars_conf_content = get_oo_vars_conf_content(node)

file "/etc/profile.d/oneops_compute_cloud_service.sh" do
  content env_vars_content
end

file "/etc/profile.d/oneops.sh" do
  content oo_vars_content
end

# ccm requires
file "/etc/profile.d/oneops.conf" do
  content oo_vars_conf_content
end

  
link "#{prefix}/etc/oneops" do
  to '/etc/profile.d/oneops.conf'
end

if node.platform != "ubuntu" && ostype !~ /windows/
  Chef::Log.info("Changing permission for /var/log/messages")
  execute "change_permission" do
    cwd("/var/log/")
    command "chmod a+r messages"
  end
end
