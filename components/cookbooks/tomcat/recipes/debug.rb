#Deprecated - Will be removed in future releases

include_recipe "tomcat::generate_variables"
include_recipe "tomcat::stop"

version=node.tomcat.version.gsub(/\..*/,"")
Chef::Log.info("Starting to debug with user #{node.tomcat_owner}");


if File.exist?("#{node.tomcat.tomcat_install_dir}/tomcat#{version}/bin/catalina.sh")
  script "debug_tomcat" do
  interpreter "bash"
  user node[:tomcat][:tomcat_owner]
  cwd  "#{node.tomcat.tomcat_install_dir}/tomcat#{version}/bin/"
  code <<-EOH
     sudo -u "#{node.tomcat_owner}" ./catalina.sh jpda start
  EOH
  end
else
  Chef::Log.info("#{node.tomcat.tomcat_install_dir}/tomcat#{version}/bin/catalina.sh file does not exists.")
end
