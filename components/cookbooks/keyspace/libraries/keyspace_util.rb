module Keyspace
    module Util
        def self.find_dc_replication_factor(node)
            cloud_map = {} 
            dc_rf = {} 
            if !node.workorder.payLoad.has_key?('keyspace_clouds')
            puts "***FAULT:FATAL=No clouds payload found. Pull the design and retry."
            e = Exception.new("no backtrace")
            e.set_backtrace("")
            raise e         
            end
            node.workorder.payLoad.keyspace_clouds.each do |c|
            key = c['ciId'].to_s
            cloud_map[key] = c['ciName']
            end
            Chef::Log.info("cloud_map : #{cloud_map.inspect} ")
            if cloud_map.empty?
            Chef::Log.info("No clouds payload found")
            return dc_rf
            end
            cloud_dc_rac_map = {}
            if !node.workorder.payLoad.has_key?("Keyspace_Cassandra")
            puts "***FAULT:FATAL=No Cassandra payload found"
            e = Exception.new("no backtrace")
            e.set_backtrace("")
            raise e         
            end
            
            cassandra = node.workorder.payLoad.Keyspace_Cassandra
            if cassandra[0].ciAttributes.has_key?("cloud_dc_rack_map")
                cloud_dc_rac_map = JSON.parse(cassandra[0][:ciAttributes][:cloud_dc_rack_map])
            end
            if cloud_dc_rac_map.nil? || cloud_dc_rac_map.empty?
            cloud_dc_rac_map = Keyspace::Util.default_dc_rack_mapping(node)
            end
        
            Chef::Log.info("cloud_dc_rac_map : #{cloud_dc_rac_map.inspect} ")
            if cloud_map.empty?
            Chef::Log.info("No cloud_dc_rac_map found")
            return dc_rf
            end
            
            node.workorder.payLoad.RequiresComputes.each do |compute|
            cloud_id = compute[:ciName].split('-').reverse[1]
            cloud_name = cloud_map[cloud_id]
                Chef::Log.info("cloud_name = #{cloud_name}")
                next unless cloud_dc_rac_map.has_key?(cloud_name)
            dc_rack = cloud_dc_rac_map[cloud_name]
            dc = dc_rack.split(":")[0]
            rf = dc_rf.has_key?(dc) ? dc_rf[dc] : 0
            rf = rf + 1
            #default to 3 if more computes
            if rf > 3
                rf = 3
            end
            dc_rf[dc] = rf
            end
            Chef::Log.info("dc_rf : #{dc_rf} ")
            return dc_rf
        end

        def self.keyspace_exists?(node, keyspace_name)
            ip = node[:ipaddress]
            command = "/opt/cassandra/bin/cqlsh #{ip} -u #{node.workorder.payLoad.Keyspace_Cassandra[0][:ciAttributes].username} -p '#{node.workorder.payLoad.Keyspace_Cassandra[0][:ciAttributes].password}' "
            keyspaces = `#{command} -e "DESCRIBE KEYSPACES;"`
            keyspaces = keyspaces.downcase.gsub('"','').gsub('\'','').split(' ')
            Chef::Log.info("existing keyspaces = #{keyspaces.join(",")}")
            existing_keyspaces = keyspaces.collect {|x| x.downcase}
            return existing_keyspaces.include?(keyspace_name.downcase)
         end
    end
end