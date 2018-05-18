#Component-specific code
require "#{$circuit_path}/circuit-oneops-1/components/cookbooks/volume/libraries/util.rb"
require "#{$circuit_path}/circuit-oneops-1/components/cookbooks/volume/libraries/raid.rb"

$storage,$device_map = get_storage($node)

$ciAttr = $node['workorder']['rfcCi']['ciAttributes']
$mount_point = $ciAttr['mount_point']
