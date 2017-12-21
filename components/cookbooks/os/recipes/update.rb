#
# Cookbook Name:: os
# Recipe:: update
#
if (node[:workorder][:rfcCi][:ciBaseAttributes].has_key?("ostype") &&
    (node[:workorder][:rfcCi][:ciBaseAttributes][:ostype] != node[:workorder][:rfcCi][:ciAttributes][:ostype]))
  exit_with_error "OS type doens't match with current configuration, consider replacing compute or change OS type to original"
else
  include_recipe "os::add"
end
