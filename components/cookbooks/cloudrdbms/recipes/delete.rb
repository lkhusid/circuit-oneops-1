# Cloud RDBMS delete recipe
#

log "CloudRDBMS BEGIN delete.rb"

include_recipe "cloudrdbms::wire_ci_attr"







log "CloudRDBMS update listofIP.log, run getCommaSeparatedListOfHosts.sh"

bash 'update_list_of_hosts' do
    cwd '/app'
    user 'app'
    code <<-EOF
       # this block runs under Linux app user
       # this VM getting DELETEd - it will remove itself from listofIP.log
       cat listofIP.log | grep -v -i `hostname -f` >templist
       mv -fv templist listofIP.log
       # update the files with the list of IPs/hosts:
       source getCommaSeparatedListOfHosts.sh
    EOF
end









ruby_block 'logs' do
    block do
        # we want this logging to happen AFTER the 'bash' block above - so we put this inside a 'ruby_block'. Otherwise it would log the contents of file commaseparatedlistofIPs BEFORE we had a chance to modify that file in the 'bash' block above
        Chef::Log.info("CloudRDBMS Update the list of IPs on other nodes too: " + `cat /app/commaseparatedlistofIPs`)
        Chef::Log.info("CloudRDBMS so the other VMs should be informed that this host is getting removed, hostname: " + `hostname`)
    end
end

execute 'find_bootstrap_node' do
    command "/app/updateClusterMembers.sh `cat /app/commaseparatedlistofIPs`"
    user "app"
    action :run
end




log "CloudRDBMS END delete.rb"
