cloud_name = node[:workorder][:cloud][:ciName]
compute_cloud_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]

if compute_cloud_service.has_key?("env_vars")
  env_vars = JSON.parse(compute_cloud_service[:env_vars])
end

runtime_context = {
  'Cloud'   =>  node[:workorder][:cloud][:ciName],
  'Env'     =>  node[:workorder][:payLoad][:Environment][0][:ciName],
  'EnvType' =>  node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile],
}

runtime_context.tap do | env_vars_hash |
  env_vars_hash['CloudDc'] = env_vars['DATACENTER'] if env_vars.has_key?('DATACENTER')
end

machine_configs = ['C:\Windows\Microsoft.NET\Framework\v2.0.50727\CONFIG\machine.config',
                   'C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\machine.config',
                   'C:\Windows\Microsoft.NET\Framework64\v2.0.50727\CONFIG\machine.config',
                   'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config']

machine_configs.each do |config|
  if ::File.exists?(config)
    dotnetframework_machine_config 'add runtime context' do
      action :add_or_update
      run_time_context runtime_context
      config_path config
    end
  end
end
