require File.expand_path('../../libraries/barbican_utils.rb', __FILE__)

secrets = get_secrets_wo()

container_name = node[:cert_container_name]
Chef::Log.info "Adding container #{container_name} ..."
if secrets.count == 4
  create_container(
   secrets[0][:secret_name],
   secrets[1][:secret_name],
   secrets[2][:secret_name],
   secrets[3][:secret_name],
   container_name,
   "certificate")
elsif secrets.count == 3
  create_container(
      secrets[0][:secret_name],
      secrets[1][:secret_name],
      secrets[2][:secret_name],
      nil,
      container_name,
      "certificate")
end

user_list = Array.new
user_list.push("neutron")
user_list.push("octavia")
user_list.push("admin")

replace_acl(container_name,user_list,"container")

