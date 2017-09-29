#
# Cookbook Name:: tomcat
# Recipe:: versioncheck
#
# Deprecated - Will be removed in future releases

include_recipe 'tomcat::versionstatus'
script="#{node[:versioncheckscript]}"

bash "CHECK_APP_VERSION" do
        code <<-EOH
          #{script}
          exit "$RETVAL"
        EOH
end
