new_size = node.workorder.rfcCi.ciAttributes["size"].gsub(/\s+/, "")
old_size = node.workorder.rfcCi.ciBaseAttributes[:size]

#this condition will help to attach same volume component on compute replace
if !old_size.nil? && new_size != old_size &&  old_size != "-1"
  Chef::Log.info("Volume will be deleted and new volume will be attached to compute")
  include_recipe "volume::delete"
  include_recipe "volume::add"
else
  Chef::Log.info("Same volume will be attached to compute")
  include_recipe "volume::add"
end