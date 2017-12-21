# Cloud RDBMS add recipe
#
# this script needs to be 100% rerunnable and backwards compatible. If we run this script twice (or more) it should still work
# ATTENTION: we can have SQL statements that WRITE data to a DR VM - but only do it in the VM we are using to bootstrap the DR cluster.  DO NOT write data in the other VMs in the DR cluster
#

# Set my needed qualities to call ansible
managedservicepass = node["cloudrdbms"]["managedservicepass"]
managedserviceuser = node["cloudrdbms"]["managedserviceuser"]
concordaddress = node["cloudrdbms"]["concordaddress"]
playbook = "stop"
  

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
    