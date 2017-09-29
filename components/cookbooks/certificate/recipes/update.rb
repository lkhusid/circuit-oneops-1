#if key-managment service barbican is present in the workload , invoke the barbican::update recipe here
if node[:workorder][:services].has_key?("keymanagement")
  include_recipe "barbican::update"
  return
end

include_recipe "certificate::add"