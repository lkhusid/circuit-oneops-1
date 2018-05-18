payload = node.workorder.payLoad
Chef::Log.info("Workorder: #{node[:workorder].to_json}")

if node.workorder.has_key?("rfcCi")
  ci = node.workorder.rfcCi
else
  ci = node.workorder.ci
end

# Validation for Zookeeper "admin" user password
if (node['zookeeper']['enable_zk_sasl_plain'] == "true" && node['zookeeper']['sasl_zk_admin_pwd'].strip.empty?)
  nozksasladminpass = "The password for 'admin' user can't be empty in SASL/Plain Configuration section."
  Chef::Log.error("FATAL: #{nozksasladminpass}")
  puts "***FAULT:FATAL= #{nozksasladminpass}"
  Chef::Application.fatal!(nozksasladminpass)
end


if ci.ciAttributes.has_key?("prod_level_checks_enabled")
  node.default[:prod_level_checks_enabled] = ci.ciAttributes.prod_level_checks_enabled
  prod_level_checks_enabled = node[:prod_level_checks_enabled]
else
  Chef::Log.warn("No prod_level_checks_enabled attribute found. This might be old deployment, please pull latest design and re-deploy")
  return
end

Chef::Log.info("======= prod_level_checks_enabled enabled = #{prod_level_checks_enabled} =====")

if (node[:workorder].has_key?("payLoad"))
    if (node[:workorder][:payLoad].has_key?("Environment"))
      profile = node[:workorder][:payLoad][:Environment][0][:ciAttributes][:profile]
      profile.downcase!
      Chef::Log.info("CI attributes profile : #{profile}")
    else
        Chef::Log.error("Expecting field \"Environment\" in #{node[:workorder][:payLoad].to_json}");
        msg = "Expecting \"Environment\" field in . #{node[:workorder][:payLoad].to_json}"
        raise "#{msg}"
        return
    end
else
    Chef::Log.error("Expecting field \"payLoad\" in node[:workorder]");
end

if profile == 'prod'
  if !prod_level_checks_enabled.eql?("true")
    Chef::Log.error("production level cloud configuration is NOT enabled for PROD profile: ")
    Chef::Log.error("environment profile      : #{profile}")
    Chef::Log.error("prod_level_checks_enabled: #{prod_level_checks_enabled}")
    # msg = "Environment Profile = #{profile}, prod_level_checks_enabled = #{prod_level_checks_enabled}. "
    # msg += "production level cloud configuration is NOT enabled for PROD profile: "
    # raise "#{msg}"
    return
  else
    Chef::Log.info("production level cloud configuration is enabled for PROD profile, Validating the minimum number of clouds and computes recommended to run an production environment. ")
    Chef::Log.info("environment profile      : #{profile}")
    Chef::Log.info("prod_level_checks_enabled: #{prod_level_checks_enabled}")
  end
else
  Chef::Log.info("No production level check is required.")
  Chef::Log.info("environment profile      : #{profile}")
  Chef::Log.info("prod_level_checks_enabled: #{prod_level_checks_enabled}")
  return
end

zkclouds = Array.new

if (node[:workorder].has_key?("payLoad"))
    if (node[:workorder][:payLoad].has_key?("Clouds_in_zk_cluster"))
        node[:workorder][:payLoad][:Clouds_in_zk_cluster].each do |cloud|
          Chef::Log.info("Adding cloud: #{cloud[:ciName]}")
          zkclouds.push(cloud[:ciName])
        end
    else
        Chef::Log.error("Expecting field \"Clouds_in_zk_cluster\" in #{node[:workorder][:payLoad].to_json}");
    end
else
    Chef::Log.error("Expecting field \"payLoad\" in node[:workorder]");
end

zkclouds = zkclouds.sort()
Chef::Log.info("Sorted array of Cloud Names: #{zkclouds}")

zknodes = Array.new
if (node[:workorder].has_key?("payLoad"))
    if (node[:workorder][:payLoad].has_key?("Computes_in_zk_cluster"))
        node[:workorder][:payLoad][:Computes_in_zk_cluster].each do |compute|
          Chef::Log.info("Adding node: #{compute[:ciName]}")
          zknodes.push(compute[:ciName])
        end
    else
        Chef::Log.fatal("Expecting field \"Computes_in_zk_cluster\" in #{node[:workorder][:payLoad].to_json}");
    end
else
    Chef::Log.fatal("Expecting field \"payLoad\" in node[:workorder]");
end

zknodes = zknodes.sort()
Chef::Log.info("Sorted array of Compute Names: #{zknodes}")

cloud_to_computes = Hash.new

if (node[:workorder].has_key?("payLoad"))
    if (node[:workorder][:payLoad].has_key?("Computes_in_zk_cluster"))
        Chef::Log.info("Computes_in_zk_cluster: #{node[:workorder][:payLoad][:Computes_in_zk_cluster].to_json}")
        node[:workorder][:payLoad][:Computes_in_zk_cluster].each do |compute|
            cloud_index = compute[:ciName].split('-').reverse[1].to_s
            if (cloud_to_computes[cloud_index] == nil)
                cloud_to_computes[cloud_index] = Array.new
            end
            cloud_to_computes[cloud_index].push(compute[:ciName])
        end
    else
        Chef::Log.warn("Field \"Computes_in_zk_cluster\" not found in #{node[:workorder][:payLoad]}");
    end
else
    Chef::Log.warn("Field \"payLoad\" not found in #{node[:workorder]}");
end
Chef::Log.info("**** cloud_to_computes: #{cloud_to_computes.to_s}")


Chef::Log.info("**** min_clouds: #{node['zookeeper']['min_clouds']}")
Chef::Log.info("**** min_computes_per_cloud: #{node['zookeeper']['min_computes_per_cloud']}")
min_clouds = node['zookeeper']['min_clouds'].to_i
min_computes_per_cloud = node['zookeeper']['min_computes_per_cloud'].to_i

if (cloud_to_computes.size < min_clouds)
    msg = "env = #{profile}, clouds = #{cloud_to_computes.size}. "
    msg += "Your cluster must have a minimum of #{min_clouds} clouds as required by high availability. "
    msg += "Please add more clouds or configure \"production level checks\" in platform:zookeeper, resource:zookeeper"
    if (profile =~ /(?i)prod/)
        raise "#{msg}"
    else
        Chef::Log.warn("#{msg}")
    end
  else
    Chef::Log.info("Deployment has required minimum number of clouds.: #{cloud_to_computes.size}")
end
clouds_with_less_computes = cloud_to_computes.select {|k,v| v.length < min_computes_per_cloud}
if (clouds_with_less_computes.size > 0)
    msg = "env = #{profile}, number of clouds with less computes = #{clouds_with_less_computes.size}. "
    msg += "Some clouds do not have #{min_computes_per_cloud} computes as required by high availability. "
    msg += "Please add more computes to the clouds or configure \"production level checks\" in platform:Zookeeper, resource:zookeeper"
    if (profile =~ /(?i)prod/)
        raise "#{msg}"
    else
        Chef::Log.warn("#{msg}")
    end
  else
    Chef::Log.info("Deployment has required minimum number of Computes.: #{min_computes_per_cloud}")
end


