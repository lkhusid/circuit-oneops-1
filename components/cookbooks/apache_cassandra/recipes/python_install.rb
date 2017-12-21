
# Reading for type of action.
#
if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
  actionName = node.workorder.rfcCi.rfcAction
else
  ci = node.workorder.ci
  actionName = node.workorder.actionName
end

version = ci.ciAttributes.version
# Install new version of python only for cassandra versions >= 2.2
if version.to_f < 2.2
  puts "Skipping insalling the 2.2.7 version of Python as it is not required for #{version} of cassandra"
  return
end

package 'zlib-devel'
package 'bzip2-devel'
package 'openssl-devel'
package 'ncurses-devel'
package 'sqlite-devel'
package 'xz'

tmp = Chef::Config[:file_cache_path]
sub_dir = "python-src/2.7.6"
tgz_file = "python-src-2.7.6.tar.xz"
tar_file = "python-src-2.7.6.tar"
dest_file = "#{tmp}/#{tgz_file}"
cloud_name = node[:workorder][:cloud][:ciName]
services = node[:workorder][:services]
cloud_services = services[:maven][cloud_name]
python_download_url = cloud_services[:ciAttributes][:url] + "content/groups/public/org/python/#{sub_dir}/#{tgz_file}"

source_list = [python_download_url]
# Reading for type of action.

if node.workorder.has_key?("rfcCi")
     ci = node.workorder.rfcCi
     actionName = node.workorder.rfcCi.rfcAction
else
     ci = node.workorder.ci
     actionName = node.workorder.actionName
end

if actionName == 'upgrade'
     `curl -o #{dest_file} #{python_download_url}`
else
     shared_download_http source_list.join(",") do
         path dest_file
         action :create
     end
end

execute "untar_python_source" do
    command "unxz #{tgz_file}; tar -xf #{tar_file}; cd Python-2.7.6; sudo ./configure --prefix=/usr/local; sudo make && sudo make altinstall"
    cwd "#{tmp}"
end

