#
# Cookbook Name:: compute
# Recipe:: update
#
if (node[:workorder][:rfcCi][:ciBaseAttributes].has_key?("size")  &&
    (node[:workorder][:rfcCi][:ciBaseAttributes][:size] != node[:workorder][:rfcCi][:ciAttributes][:size]))
  exit_with_error "Instance size doens't match with current configuration, consider replacing compute or change instace size to original"
else
  include_recipe "compute::add"
end
