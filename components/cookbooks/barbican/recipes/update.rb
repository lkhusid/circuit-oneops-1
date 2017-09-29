config_items_changed= node[:workorder][:rfcCi][:ciBaseAttributes] # config_items_changed is empty if there no configuration change in lb component
if !config_items_changed.empty? # old_config is empty if there no configuration change in certificate component
  include_recipe "barbican::delete"
  include_recipe "barbican::add"
end