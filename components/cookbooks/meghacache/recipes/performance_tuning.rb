
package 'tuned' do
  action :install
end

tuned_profile = 'cache-latency'

directory "/etc/tuned/#{tuned_profile}" do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

cookbook_file 'tuned-profile' do
  cookbook 'meghacache'
  path "/etc/tuned/#{tuned_profile}/tuned.conf"
  source 'tuned.conf'
  owner 'root'
  group 'root'
  mode 0644
end


ruby_block 'set_tuned_profile' do
  block do
    Chef::Log.info("tuned-adm - #{`tuned-adm active`}")
    `sudo tuned-adm profile #{tuned_profile}`
    Chef::Log.info("Update tuned-adm - #{`tuned-adm active`}")
  end
  not_if { `tuned-adm active`.include?(tuned_profile) }
end
