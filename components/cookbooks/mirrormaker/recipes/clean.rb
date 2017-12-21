#
# Cookbook Name:: mirrormaker 
# Recipe:: clean
#
#

bash "clean_up_log_dir" do
  user "#{node['mirrormaker'][:user]}"
  cwd "#{node['mirrormaker'][:log_dir]}"
  code <<-EOH
    rm -rf *
    EOH
end



