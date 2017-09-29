# install_rpm - Install the Centrify RPM
#
# This recipe downloads and installs the Centrify RPM.

Chef::Log.info("Running #{node['app_name']}::install_rpm")

require File.expand_path("../centrify_helper.rb", __FILE__)

configName = node['app_name']
configNode = node[configName]

cent_cache_path = Chef::Config[:file_cache_path]

serviceConfig = get_service_config()

centrify_url = serviceConfig[:url]
rpm_file = cent_cache_path + "/_centrify.rpm"

# remote_file produces way too much output in debug environments
bash "download_centrify" do
    user "root"
    code <<-EOF
        /usr/bin/curl "#{centrify_url}" -o "#{rpm_file}"
    EOF
    not_if "/bin/ls #{rpm_file}"
end

# Install the RPM
execute "install_centrify" do
  user    "root"
  command "rpm -ivh #{rpm_file}"
  not_if "rpm -qa |grep -i centrify"
end

# Also install ksh for a shell for users that may have
# it configured as their shell
package 'ksh'
