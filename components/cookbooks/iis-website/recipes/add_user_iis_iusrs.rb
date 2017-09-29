usernames = JSON.parse(node['iis-website']['iis_iusrs_group_service_accounts'])

Chef::Log.info("Accounts: #{usernames} will be added to IIS_IUSRS group") if !usernames.empty?

group "IIS_IUSRS" do
  action :create
  members usernames
  append true
  not_if { usernames.empty? }
end
