
# gets the binary distribution using standard apache distribution path convention:
#  /tomcat/tomcat-7/v7.0.41/bin/apache-tomcat-7.0.41.tar.gz
#
# mirrors attribute is an array of uri's prefixing the distribution path convention
major_and_minor = node.tomcat.version
major_version = major_and_minor.gsub(/\..*/,"")

build_version = node.tomcat.build_version

if major_and_minor.to_s == "6.0" || major_and_minor.to_s == "7.0"
  full_version = "#{major_and_minor}.#{build_version}"
  #full_version = major_and_minor
else
  full_version = major_and_minor
end

# mirrors - default value in metadata are first 2
# http://archive.apache.org/dist
# http://apache.cs.utah.edu/ (no /dist)
# + /tomcat/tomcat-7/v7.0.29/bin/apache-tomcat-7.0.29.tar.gz
tarball = "tomcat/tomcat-#{major_version}/v#{full_version}/bin/apache-tomcat-#{full_version}.tar.gz"

# create parent dir (keep ownership as root) if doesnt exist
directory node['tomcat']['tomcat_install_dir'] do
  action :create
  not_if "test -d #{node.tomcat.tomcat_install_dir}"
end
dest_file = "#{node.tomcat.tomcat_install_dir}/apache-tomcat-#{full_version}.tar.gz"

##Get apache mirror configured for the cloud, if no mirror is defined for component.
cloud_name = node[:workorder][:cloud][:ciName]
services = node[:workorder][:services]

if File.file?("/etc/oneops-tools-inventory.yml") && YAML.load_file("/etc/oneops-tools-inventory.yml").key?("tomcat_#{full_version}")

  # if on fast deploy image copy tomcat instead of downloading
  runtimes = YAML.load_file("/etc/oneops-tools-inventory.yml")
  if File.file?("#{runtimes["tomcat_#{full_version}"]}")
    dest_file = runtimes["tomcat_#{full_version}"]
  else
    Chef::Log.error("Failed on Fast image. File #{runtimes["tomcat_#{full_version}"]} specified in /etc/oneops-tools-inventory.yml does not exist")
    exit 1
  end
else

  if services.nil? || !services.has_key?(:mirror)
    Chef::Log.error("Please make sure  cloud '#{cloud_name}' has mirror service with 'apache' eg {apache=>http://archive.apache.org/dist}")
    exit 1
  end
  mirrors = JSON.parse(services[:mirror][cloud_name][:ciAttributes][:mirrors])
  if mirrors.nil? || !mirrors.has_key?('apache')
    Chef::Log.error("Please make sure  cloud '#{cloud_name}' has mirror service with 'apache' eg {apache=>http://archive.apache.org/dist}")
    exit 1
  end
  mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
  source_list = mirrors['apache'].split(",").map { |mirror| "#{mirror}/#{tarball}" }
  shared_download_http source_list.join(",") do
    path dest_file
    action :create
  end
end

  tar_flags = "--exclude webapps/ROOT"
  execute "tar #{tar_flags} -zxf #{dest_file}" do
    cwd node.tomcat.tomcat_install_dir
  end


execute "rm -fr tomcat#{major_version}" do
  cwd node.tomcat.tomcat_install_dir
end

link "#{node.tomcat.tomcat_install_dir}/tomcat#{major_version}" do
  to "#{node.tomcat.tomcat_install_dir}/apache-tomcat-#{full_version}"
end

username = node.tomcat_owner
group = node.tomcat_group

execute "groupadd #{group}" do
  returns [0,9]
end

execute "useradd -g #{group} -d #{node.tomcat.tomcat_install_dir}/tomcat#{major_version} #{username}" do
  returns [0,9]
end


execute "chown -R #{username}:#{group} apache-tomcat-#{full_version}" do
  cwd node.tomcat.tomcat_install_dir
end

base_dir = "#{node.tomcat.tomcat_install_dir}/apache-tomcat-#{full_version}"
node.set["tomcat"]["base"] = base_dir
node.set["tomcat"]["home"] = base_dir

cookbook_file 'custom-root-file' do
  source 'ROOT.tar.gz'
  path "#{base_dir}/webapps/ROOT.tar.gz"
  owner username
  group group
  mode '0755'
  action :create
  notifies :create, 'directory[create-root-folder]', :immediately
  not_if  { File.exist?("#{base_dir}/webapps/ROOT") }
end

directory "create-root-folder" do
  path "#{base_dir}/webapps/ROOT"
  owner username
  group group
  mode '0755'
  action :nothing
  notifies :run, 'execute[untar-custom-root-file]', :immediately
end

 execute "untar-custom-root-file" do
   command 'tar -zxf ROOT.tar.gz -C ROOT'
   cwd "#{base_dir}/webapps"
   action :nothing
   notifies :delete, 'file[delete-custom-root-file]', :immediately
 end

file 'delete-custom-root-file' do
  path  "#{base_dir}/webapps/ROOT.tar.gz"
  action  :nothing
end

directory "#{base_dir}/webapps/examples" do
  recursive true
  action :delete
end

directory "#{base_dir}/webapps/docs" do
  recursive true
  action :delete
end

template "#{base_dir}/bin/setenv.sh" do
  source "setenv.sh.erb"
  owner username
  group group
  mode "0755"
end
#Ignore foodcritic(FC023) warning here.  Looks for the file resource and since it cannot find it the recipe fails if we use the not_if directive and the content is empty
if !node[:tomcat][:post_startup_command].nil? # ~FC023
  file "#{base_dir}/bin/poststartup.sh" do
    content node["tomcat"]["post_startup_command"].gsub(/\r\n?/,"\n")
    owner username
    group group
    mode "0755"
  end
end

template "/etc/init.d/tomcat#{major_version}" do
  source "generic_initd.erb"
  mode "0755"
end


template "#{base_dir}/conf/server.xml" do
  source "server#{major_version}.xml.erb"
  owner username
  group group
  mode "0644"
end

template "#{base_dir}/conf/web.xml" do
  source "web#{major_version}.xml.erb"
  owner username
  group group
  mode "0644"
end



template "#{base_dir}/conf/context.xml" do
	 source "context7.xml.erb"
	 mode "0644"
	end


template "#{base_dir}/conf/tomcat-users.xml" do
  source "tomcat-users.xml.erb"
  owner username
  group group
  mode "0644"
end

template "#{base_dir}/conf/catalina.policy" do
  source "catalina.policy.erb"
  owner username
  group group
  mode "0644"
end

unless node["tomcat"]["access_log_dir"].start_with?("/")
  node.set['tomcat']['access_log_dir'] =  "#{base_dir}/#{node.tomcat.access_log_dir}"
end
#Set up the log directories
log_dir=node["tomcat"]["logfiles_path"]
access_log_dir=node["tomcat"]["access_log_dir"]
Chef::Log.info("Installation type binary - access log #{access_log_dir} logpath : #{log_dir}")
[log_dir,access_log_dir].each do |dir_name|
  directory dir_name do
    action :create
    recursive true
    not_if "test -d #{dir_name}"
  end
  execute "chown -R #{node.tomcat_owner}:#{node.tomcat_group} #{dir_name}"
end
