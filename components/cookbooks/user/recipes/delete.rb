username = node[:user][:username]
group = JSON.parse(node[:user][:group])
is_windows = node['platform'] =~ /windows/
group.push('Administrators') if is_windows && !group.include?('Administrators')

if !is_windows
  Chef::Log.info("Stopping the nslcd service")
  `sudo killall -9  /usr/sbin/nslcd`

  if username != "root"
    execute "pkill -9 -u #{username} ; true"
  end
end

user username do
  action :remove
end

group username do
  action :remove
  not_if {is_windows}
end

#in windows remove the user from its groups
group.each do |g|
  group g do
    excluded_members username
    append true
    action :manage
  end
end if is_windows
