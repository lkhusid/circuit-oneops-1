#Check whether user selected to run upgradesstables
args = ::JSON.parse(node.workorder.arglist)
v_upgrade_sstables = args["UpgradeSSTables"]

unless v_upgrade_sstables.nil?
	v_upgrade_sstables = v_upgrade_sstables.to_s.downcase
	if (v_upgrade_sstables == 'yes' || v_upgrade_sstables == "no")
		Chef::Log.info("User selected #{v_upgrade_sstables} for running upgradesstables")
	else
		Chef::Log.error("Invalid value for upgradesstable argument.Enter yes or no only.")
		return
	end
end

#Prerequisites
if !node.workorder.ci.ciAttributes.has_key?("node_version")
    Chef::Log.info("Please update the version in transition and retry the upgrade")
    return
end

node_version = node.workorder.ci.ciAttributes.node_version
if node_version == nil || node_version.empty?
   Chef::Log.info("No node version found, please select new version and update before upgrade")
   return
end
Chef::Log.info("Node version : #{node_version}")

current_version = node.workorder.ci.ciAttributes.node_version
new_version = node.workorder.ci.ciAttributes.version

# Check whether versions are correct
if ((Gem::Version.correct?(current_version)) && Gem::Version.correct?(new_version))
	Chef::Log.info("Upgrading from #{current_version} to #{new_version}")
else
	Chef::Log.fatal("Wrong versions: upgrading from #{current_version} to #{new_version}")
	raise
end

version_upgrade_check = Gem::Version.new(current_version) <=> Gem::Version.new(new_version)

puts "version_upgrade_check = #{version_upgrade_check}"

if version_upgrade_check == 1
    message = "Version down grade is not supported."
	puts "***FAULT:FATAL=" + message
	puts "*************** #{message} ***********"
    e = Exception.new("no backtrace")
    e.set_backtrace("")
    raise e
elsif version_upgrade_check == 0
	puts "******* No version change hence skipping upgrade *****"
	Chef::Log.error("No version change hence skipping upgrade")
	return
end

major_version_upgrade_check = Gem::Version.new(new_version) <=> Gem::Version.new(current_version).bump
puts "major_version_upgrade_check = #{major_version_upgrade_check}"

#Pre upgrade - Running upgradesstables.

if (major_version_upgrade_check == 0 || major_version_upgrade_check == 1)
	puts "Major Version upgrade detected. Running upgradesstables prior to upgrade to make sure all sstables are matched with #{current_version}"
	cmd = `sudo /app/cassandra/current/bin/nodetool upgradesstables`
	puts "Updatesstable : #{cmd}"
else
	puts "Minor Version upgrade detected, Skipping pre-upgradesstables."
end

cmd = `sudo /opt/cassandra/bin/nodetool drain`
puts "Draining the node : #{cmd}"

include_recipe "apache_cassandra::stop"
include_recipe "apache_cassandra::add"
include_recipe "apache_cassandra::restart"

#Post upgrade - Running upgradesstables.

if v_upgrade_sstables == 'yes'
    puts "User Selected to run upgradesstables after upgrade"
	cmd = `sudo /opt/cassandra/bin/nodetool upgradesstables`
	puts "Updatesstable : #{cmd}"
else
    puts "User selected to skip running upgradesstables. User is responsible for running upgradesstables after the upgrade"
end

puts "***RESULT:node_version=" + new_version
