# Cloud RDBMS restore recipe
#
# this script needs to be 100% rerunnable and backwards compatible. If we run this script twice (or more) it should still work
# ATTENTION: we can have SQL statements that WRITE data to a DR VM - but only do it in the VM we are using to bootstrap the DR cluster.  DO NOT write data in the other VMs in the DR cluster
#

# Set my needed qualities to call ansible
concordaddress = node['cloudrdbms']['concordaddress']
managedserviceuser = node['cloudrdbms']['managedserviceuser']
managedservicepass = node['cloudrdbms']['managedservicepass']
playbook = "restore"
clustername = node['cloudrdbms']['clustername']
drclouds = node['cloudrdbms']['drclouds']
cloudrdbmspackversion = node['cloudrdbms']['cloudrdbmspackversion']

# Assume that every node is healthy and already joined the primary cluster.
# This recipe is destructive, all existing data will be removed
#

if ! File.file?('/usr/local/bin/objectstore')
  Chef::Log.info("CloudRDBMS exit restore because objectstore not installed: /usr/local/bin/objectstore")
  return
end

current_node=`hostname -f`
current_node.strip!
Chef::Log.info("CloudRDBMS starts restore procedure at #{current_node}")

#retrieve the parameter values entered by customers
args=::JSON.parse(node.workorder.arglist)

#if the time value is not set, it is default to the current time
restoreTime=args["time"]
if restoreTime.to_s.strip.length == 0
  restoreTime=`date -u "+%Y_%m_%d-%H_%M_%S"`
else
  if restoreTime  !~ /^[0-9]{4}.[0-9]{2}.[0-9]{2}.[0-9]{2}.[0-9]{2}.[0-9]{2}$/
    raise RuntimeError, "CloudRDBMS invalid restore time format, should be like 2016_09_00-01_04_00"
  end
end




Chef::Log.info("CloudRDBMS get var info")
log "CloudRDBMS Show environment for concordaddress: '#{concordaddress}'"
log "CloudRDBMS Show environment for managedserviceuser: '#{managedserviceuser}'"
log "CloudRDBMS Show environment for clustername: '#{clustername}'"
log "CloudRDBMS Show environment for drclouds: '#{drclouds}'"
log "CloudRDBMS Show environment for cloudrdbmspackversion: '#{cloudrdbmspackversion}'"
log "CloudRDBMS Show environment for playbook: '#{playbook}'"


# if we do a deployment using multiple-clouds, this below will work, it will "see" all IP addresses
string_of_ips = ""

File.readlines("/app/listofHostsInCluster.log").each do |n|
    sLoopHostname = n.strip!
    sLoopIP = `nslookup #{sLoopHostname} | awk -F":" '{if($1 == "Address") print $2}' | tail -1`.strip!
    # this is the SHORT hostname, not the FULL hostname:
    Chef::Log.info("CloudRDBMS IP inside main loop, IP/HOST=" + sLoopIP)
    if string_of_ips.length == 0
        string_of_ips = "\"" + sLoopIP
    else
        string_of_ips = string_of_ips + "\",\"" + sLoopIP
    end
end
string_of_ips = string_of_ips + "\""
Chef::Log.info("CloudRDBMS IP addresses for the cluster:BEGIN")
Chef::Log.info(string_of_ips)
Chef::Log.info("CloudRDBMS IP addresses for the cluster:END")


Chef::Log.info("CloudRDBMS IP addresses for this host:BEGIN")
local_ip=`hostname -i`.strip!
current_node=`hostname -f`.strip!
Chef::Log.info(local_ip)
Chef::Log.info("CloudRDBMS IP addresses for this host:END")

log "CloudRDBMS get concord script get_concord_status.sh"

template "/app/get_concord_status.sh" do
    source "get_concord_status.erb"
    owner "app"
    group "app"
    mode "0755"
end

file '/app/#{playbook}.yml' do
  action :delete
end



template_variables = {
  :concordaddress         => concordaddress,
  :managedserviceuser     => managedserviceuser,
  :cloudrdbmspackversion  => cloudrdbmspackversion,
  :clustername            => clustername,
  :drclouds               => drclouds,
  :cloudrdbmspackversion  => cloudrdbmspackversion,
  :playbook               => playbook,
  :string_of_ips          => string_of_ips,
  :local_ip               => local_ip,
  :current_node           => current_node,
  :time                   => args["time"],
  :oneops_cloud_tenant    => args["organization"],
  :oneops_assembly        => args["assembly"],
  :oneops_environment     => args["environment"],
  :oneops_platform        => args["platform"]
}

template "/app/#{playbook}.yml" do
    variables     template_variables
    source "restore_w_oneops_vars.erb"
    owner "app"
    group "app"
    mode "0755"
  verify { args["organization"].to_s.strip.length != 0 }
  verify { args["assembly"].to_s.strip.length != 0 }
  verify { args["environment"].to_s.strip.length != 0 }
  verify { args["platform"].to_s.strip.length != 0 }
end

template "/app/#{playbook}.yml" do
    variables     template_variables
    source "restore.erb"
    owner "app"
    group "app"
    mode "0755"
  verify { args["organization"].to_s.strip.length == 0 }
  verify { args["assembly"].to_s.strip.length == 0 }
  verify { args["environment"].to_s.strip.length == 0 }
  verify { args["platform"].to_s.strip.length == 0 }
end

log "CloudRDBMS concord: start ansible job"
### Start Concord Job for ansible ####
bash 'start_ansible' do
    cwd '/app'
    user 'app'
    code <<-EOF
      # Set my needed qualities to call ansible
      mv "#{playbook}.yml" _main.yml
      curl  -u "#{managedserviceuser}:#{managedservicepass}" -F request=@_main.yml -F org="Default" -F project="cloudrdbms" -F repo="#{cloudrdbmspackversion}" -F entryPoint="ansibleFlow" http://#{concordaddress}/api/v1/process >./curl_#{playbook}.out
      RC=$?
      echo "running the command exited with return code ${RC}"
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
            return_code_curl = $?.exitstatus
            instanceId=`awk -F'\"' '{if($2=="instanceId")print $4}' /app/status`
            if return_code_curl != 0
              puts "Exit status: $?.exitstatus"
              raise RuntimeError, "Some error happened while trying to get the status"
            elsif ( status == "RUNNING" ) || ( status == "ENQUEUED" ) || ( status == "STARTING" )
              curlComplete = 0
              curlAttempt += 1
              Chef::Log.info("CloudRDBMS attempt #{curlAttempt} of 360 on instanceID(#{instanceId}), current status is #{status}.")
              sleep(10)
            elsif ( status == "FINISHED" )
              Chef::Log.info("CloudRDBMS attempt #{curlAttempt} on instanceID(#{instanceId}) #{status}.")
              curlComplete = 1
            else
              raise RuntimeError, "[CloudRDBMS] Error: Concord shows '#{status}' on instanceID(#{instanceId})!"
            end
          end
        end
      end
    end
# END bash 'validate_complete'
