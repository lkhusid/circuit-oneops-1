ruby_block "replace_address option" do
  block do
    active_nodes = node[:initial_seeds].join(",")
    # grab a secure key for ssh
    puuid = (0..32).to_a.map{|a| rand(32).to_s(32)}.join
    ssh_key_file = "/tmp/"+puuid
    `sudo echo '#{node.workorder.payLoad[:SecuredBy][0][:ciAttributes][:private]}' >#{ssh_key_file}; chmod 400 #{ssh_key_file}`
    localIp = node[:ipaddress]
    
    #update seeds in cassandra.yaml in all other nodes
    computes = node.workorder.payLoad.has_key?("RequiresComputes") ? node.workorder.payLoad.RequiresComputes : node.workorder.payLoad.computes
    computes.each do |n|
      ip = n[:ciAttributes][:private_ip]
      if localIp != nil && localIp != ip
        cmd = `sudo ssh -i #{ssh_key_file} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null oneops@#{ip} sudo sh /tmp/replace_seed_info.sh #{active_nodes}`
        puts "Update seeds result : #{cmd}"
      end  
    end
  end
end