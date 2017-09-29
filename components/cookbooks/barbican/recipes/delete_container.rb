require File.expand_path('../../libraries/barbican_utils.rb', __FILE__)

container_name = node[:cert_container_name]
Chef::Log.info "Deleting container #{container_name} ..."

if delete_container(node[:cert_container_name]) == false
  raise "failed to delete the secret #{secret[:secret_name]}"
end
