#
# Cookbook Name:: os
# Recipe:: update
#
if (node[:workorder][:rfcCi][:ciBaseAttributes].has_key?("ostype") &&
    (node[:workorder][:rfcCi][:ciBaseAttributes][:ostype] != node[:workorder][:rfcCi][:ciAttributes][:ostype]))
  exit_with_error "OS type doens't match with current configuration, consider replacing compute or change OS type to original"
elsif is_propagate_update
  cur_tag = JSON.parse(node[:workorder][:rfcCi][:ciAttributes][:tags])
  ##Tag the current time-stamp.
  cur_ts = Time.now.utc.iso8601
  tags = {
      "security"=> cur_ts
  }
  puts "***RESULT:tags="+JSON.dump(cur_tag.merge(tags))

  include_recipe "os::add-conf-files"
else
  include_recipe "os::add"
end
