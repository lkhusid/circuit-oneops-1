Chef::Log.info("haveged enabled: #{node['enterprise_server']['global']['haveged_enabled']} : Haveged will be installed if platform is centos with major version 7 and more.")

if (node['enterprise_server']['global']['haveged_enabled'] == 'true' && node["platform"] == 'centos' && node["platform_version"].to_f >= 7.0)
    Chef::Log.info("Installing haveged...")
    yum_package 'haveged' do
        retries   2
        timeout   60
        action    :install
    end
    include_recipe 'enterprise_server::start_haveged'
end
