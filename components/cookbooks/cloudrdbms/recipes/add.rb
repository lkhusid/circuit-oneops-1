# Cloud RDBMS add recipe
#
# this script needs to be 100% rerunnable and backwards compatible. If we run this script twice (or more) it should still work
# ATTENTION: we can have SQL statements that WRITE data to a DR VM - but only do it in the VM we are using to bootstrap the DR cluster.  DO NOT write data in the other VMs in the DR cluster
#
include_recipe "cloudrdbms::wire_ci_attr"

# Set my needed qualities to call ansible
concordaddress = node['cloudrdbms']['concordaddress']
managedserviceuser = node['cloudrdbms']['managedserviceuser']
managedservicepass = node['cloudrdbms']['managedservicepass']
playbook = "add"
# this below gets value(s) from metadata - user input parameter
clustername = node['cloudrdbms']['clustername']
# this below gets value(s) from default.rb  and  wire_ci_attr.rb
nexusurl = node['cloudrdbms']['urlbase']
# this below gets value(s) from metadata - user input parameter
drclouds = node['cloudrdbms']['drclouds']
# this below comes from default.rb
artifactnexusurl = node['cloudrdbms']['artifacturlbase']
# this below gets value(s) from metadata - user input parameter
artifactversion = node['cloudrdbms']['artifactversion']
# this will use a specific version (chosen by the user) or it will dynamically find out what the LATEST version is. That means if the user chooses the 'special version' that we call LATEST-RELEASE (instead of choosing a specific version like 0.2.13 for example), it will always find the artifact in nexus. If the user chooses a specific version, it is possible that this version does not exist in nexus. This calls the 'CloudrdbmsArtifact' library:
artifactversion, artifactversion2, artifactnexusurl = CloudrdbmsArtifact::get_latest_version(artifactnexusurl, artifactversion)
# zookeeper version, internally defined, not expose to oneops
zookeeperversion = node['cloudrdbms']['zookeeperversion']
# this below gets value(s) from wire_ci_attr.rb
cloudrdbmspackversion = node['cloudrdbms']['cloudrdbmspackversion']

runOnEnv = node['cloudrdbms']['runOnEnv']
  
Chef::Log.info("CloudRDBMS get_var_files")
log "CloudRDBMS Show environment for concordaddress: '#{concordaddress}'"
log "CloudRDBMS Show environment for managedserviceuser: '#{managedserviceuser}'"
log "CloudRDBMS Show environment for managedservicepass: '#{managedservicepass}'"
log "CloudRDBMS Show environment for clustername: '#{clustername}'"
log "CloudRDBMS Show environment for nexusurl: '#{nexusurl}'"
log "CloudRDBMS Show environment for drclouds: '#{drclouds}'"
log "CloudRDBMS Show environment for artifactnexusurl: '#{artifactnexusurl}'"
log "CloudRDBMS Show environment for artifactversion: '#{artifactversion}'"
log "CloudRDBMS Show environment for zookeeperversion: '#{zookeeperversion}'"
log "CloudRDBMS Show environment for cloudrdbmspackversion: '#{cloudrdbmspackversion}'"
log "CloudRDBMS Show environment for playbook: '#{playbook}'"

# get list of IPs - for the VMs being deployed
IParray = Array.new
ci = node.workorder.rfcCi
cloud_index = ci[:ciName].split('-').reverse[1].to_i
# if we do a deployment using multiple-clouds, this below will work, it will "see" all IP addresses
nodes = node.workorder.payLoad.RequiresComputes
string_of_ips = ""

nodes.each do |n|
    sLoopIP = n[:ciAttributes][:dns_record]
    # this is the SHORT hostname, not the FULL hostname:
    IParray.push(sLoopIP)
    Chef::Log.info("CloudRDBMS IP inside main loop, IP/HOST=" + sLoopIP)
    if string_of_ips.length == 0
        string_of_ips = sLoopIP
    else
        string_of_ips = string_of_ips + "," + sLoopIP
    end
end
Chef::Log.info("CloudRDBMS IP addresses for the cluster:BEGIN")
Chef::Log.info(string_of_ips)
Chef::Log.info("CloudRDBMS IP addresses for the cluster:END")

file '/app/listofIPfromworkorder.log' do
  action :delete
end

log "CloudRDBMS IP addresses for the cluster (inside array loop):"
IParray.each do |sIP|
   log "CloudRDBMS IP = " + sIP.to_s + "<endIP>"
   bash 'logIP' do
       cwd '/app'
       code <<-EOF
          # this block runs under Linux root user
          # this line below shows how to pass a variable from Chef to a Linux bash script block:
          echo "#{sIP}" >>listofIPfromworkorder.log
       EOF
   end
end

log "CloudRDBMS get concord script run_concord_ansible.sh"

template "/app/run_concord_ansible.sh" do
    source "run_concord_ansible.erb"
    owner "app"
    group "app"
    mode "0755"
end
template "/app/get_concord_status.sh" do
    source "get_concord_status.erb"
    owner "app"
    group "app"
    mode "0755"
end

file '/app/source_file.sh' do
  action :delete
end

template_variables = {
  :concordaddress         => concordaddress,
  :managedserviceuser     => managedserviceuser,
  :cloudrdbmspackversion  => cloudrdbmspackversion,
  :clustername            => clustername,
  :nexusurl               => nexusurl,
  :drclouds               => drclouds,
  :artifactnexusurl       => artifactnexusurl,
  :artifactversion        => artifactversion,
  :zookeeperversion       => zookeeperversion,
  :cloudrdbmspackversion  => cloudrdbmspackversion,
  :runOnEnv               => runOnEnv,
}

template "/app/source_file.sh" do
    variables     template_variables
    source "source_file.erb"
    owner "app"
    group "app"
    mode "0755"
end

log "CloudRDBMS concord: start ansible job"
### Start Concord Job for ansible ####
bash 'start_ansible' do
    cwd '/app'
    user 'app'
    code <<-EOF
       # Set my needed qualities to call ansible
       export managedservicepass="#{managedservicepass}"
       export playbook="#{playbook}"
       source /app/source_file.sh
       ./run_concord_ansible.sh
      RC=$?
      echo "run_concord_ansible.sh exited with return code ${RC}"

    EOF
end

# END bash 'start_ansible'

log "CloudRDBMS concord: Wait for job to exit concord job"
# Wait for job to exit concord job
ruby_block 'validate_complete' do
    block do
      curlAttempt=1
      curlComplete=0
      while (curlComplete == 0) && (curlAttempt < 360) do
          begin
            status=`export playbook="#{playbook}" concordaddress="#{concordaddress}" managedserviceuser="#{managedserviceuser}" managedservicepass="#{managedservicepass}" && /app/get_concord_status.sh`
            if $?.exitstatus != 0
              puts "Exit status: $?.exitstatus"
              raise RuntimeError, "Some error happened while trying to get the status"
            elsif ( status == "RUNNING" ) || ( status == "ENQUEUED" )
              curlComplete = 0
              curlAttempt += 1
              Chef::Log.info("CloudRDBMS attempt #{curlAttempt} of 360, current status is #{status}.")
              sleep(10)
            elsif ( status == "FINISHED" )
              curlComplete = 1
            else
              raise RuntimeError, "[CloudRDBMS] Error: Concord shows '#{status}'!"
            end
          end
        end
      end
    end
# END bash 'validate_complete'
    