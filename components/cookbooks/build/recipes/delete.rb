#node.workorder.rfcCi.ciName
install_dir = node[:workorder][:rfcCi][:ciAttributes][:install_dir]

if (install_dir.empty? || install_dir.nil?)
  install_dir = "/opt/build"
end
Chef::Log.info("Using installation directory #{install_dir}")

directory "#{install_dir}" do
  recursive true
  action :delete
end