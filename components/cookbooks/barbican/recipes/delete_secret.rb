require File.expand_path('../../libraries/barbican_utils.rb', __FILE__)


secrets = get_secrets_wo()

secrets.each do |secret|
  Chef::Log.info "Deleting #{secret[:secret_name]} ... "
  if delete_secret(secret[:secret_name]) == false
    raise "failed to delete the secret #{secret[:secret_name]}"
  end
end
