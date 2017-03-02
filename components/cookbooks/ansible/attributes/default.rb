default['python']['install_method'] = 'package'

if python['install_method'] == 'package'
  case platform
  when "smartos"
    default['python']['prefix_dir']         = '/opt/local'
  else
    default['python']['prefix_dir']         = '/usr'
  end
else
  default['python']['prefix_dir']         = '/usr/local'
end


default['python']['pip_location'] = "#{node['python']['prefix_dir']}/bin/pip"
default['python']['virtualenv_location'] = "#{node['python']['prefix_dir']}/bin/virtualenv"
default['python']['setuptools_version'] = nil # defaults to latest
default['python']['virtualenv_version'] = nil

