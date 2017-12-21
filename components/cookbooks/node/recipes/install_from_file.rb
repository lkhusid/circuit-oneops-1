#
# Cookbook Name:: nodejs
# Recipe:: Install_from_file
#
require 'yaml'

runtimes = YAML.load_file("/etc/oneops-tools-inventory.yml")

runtime_path = runtimes["nodejs_#{node['nodejs']['version']}"]
Chef::Log.info("Runtime path is #{runtime_path}")

package_stub = "node-v#{node['nodejs']['version']}-linux-x64"
Chef::Log.info("OneOps CI package_stub : #{package_stub}")

destination_dir = node['nodejs']['dir']
Chef::Log.info("OneOps CI destination_dir : #{destination_dir}")

execute "install package to system" do
  command <<-EOF
            tar xf #{runtime_path} \
            --strip-components=1  --no-same-owner \
            -C #{destination_dir} \
            #{package_stub}/bin \
            #{package_stub}/lib \
            #{package_stub}/share
  EOF
end

execute "set npm registry" do
  command "#{node['nodejs']['dir']}/bin/npm config set registry #{node['nodejs']['npm_src_url']}"
  only_if { node['nodejs']['npm_src_url'] }
end

execute "set npm strict-ssl" do
  command "#{node['nodejs']['dir']}/bin/npm config set strict-ssl false"
  only_if { node['nodejs']['npm_src_url'] }
end

execute "update npm" do
  command "#{node['nodejs']['dir']}/bin/npm install npm@#{node['nodejs']['npm']} -g"
  not_if "#{node['nodejs']['dir']}/bin/npm -v 2>&1 | grep '#{node['nodejs']['npm']}'"
end
