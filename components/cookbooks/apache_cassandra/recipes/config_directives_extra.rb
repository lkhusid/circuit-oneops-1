require 'json'
#Replace seed list with the provided as config parameter
ruby_block 'update_config_directives_extra' do
  block do
    if node.workorder.has_key?("rfcCi")
      ci = node.workorder.rfcCi
    else
      ci = node.workorder.ci
    end
    cfg = JSON.parse(ci.ciAttributes.config_directives)
    seeds = cfg.delete("seeds")
    puts "****************** seeds = #{seeds} ****************"
    if(seeds != nil && !seeds.empty?)
      cmd = `sudo sh /tmp/replace_seed_info.sh #{seeds}`
    end
  end
end