#
# Cookbook Name:: kafka
# Recipe:: coordinate_kafka_start.rb
#
# Copyright 2015, @WalmartLabs
#
# All rights reserved - Do Not Redistribute

# the following implmentation is based on this template:
# https://github.com/bijugs/chef-bach/blob/kafka_rr/cookbooks/kafka-bcpc/recipes/coordinate.rb

# get the list of ZK host and find the first working zookeeper node
# because of https://github.com/zk-ruby/zookeeper/issues/21 we have to find the first live ZK, rather than giving a list of ZK host

zk_hosts = `/bin/grep zookeeper.connect= /etc/kafka/server.properties | awk -F\= '{print $2}'`.split(",")
first_live_zk_host = ""

zk_hosts.each do |zk|
    require 'ping'
    host = zk.split(":")[0]
    port = zk.split(":")[1]
    Chef::Log.info("loop zk: #{zk}")
    # use Ping to check if the current Zookeeper is working on this node
    ret = Ping.pingecho host, 10, port
    Chef::Log.info("loop ret: #{ret}")
    if ret
      first_live_zk_host = zk
      break
    end
end

Chef::Log.info("first working zk host: #{first_live_zk_host}")

#
# znode is used as the locking mechnism to control restart of services. The following code is to build the path
# to create the znode before initiating the restart of Kafka service
#
lock_znode_path = format_restart_lock_path("/","kafka-rolling-restart")

#
# When there is a need to restart kafka service, a lock need to be taken so that the restart is sequenced preventing all nodes being down at the same time
# If there is a failure in acquiring a lock with in a certian period, the restart is scheduled for the next run on chef-client on the node.
# To determine whether the prev restart failed is the node attribute node[:bcpc][:kafka][:restart_failed] is set to true
#
# This ruby block implements a very naive failure handling: all restarts are blocked until the the lock owner removes the its lock
#
ruby_block "handle_prev_kafka_restart_failure" do
    block do
        wait_kafka_restart = 0
        while true
            lock_name = get_restart_lock_holder(lock_znode_path, first_live_zk_host)
            if lock_name.nil?
                Chef::Log.info("There is no lock holder in Zookeeper, go ahead and coontinue restart.")
                break;
                else
                Chef::Log.info("Lock name is: " + lock_name)
                if my_restart_lock?(lock_znode_path, first_live_zk_host, node[:fqdn])
                    rel_restart_lock(lock_znode_path, first_live_zk_host, node[:fqdn])
                    Chef::Log.info("My lock! I am releasing it.")
                end
            end
            wait_kafka_restart += 1
            Chef::Log.info("handle_prev_kafka_restart_failure: Sleep for #{wait_kafka_restart} time.")
            sleep(node[:kafka][:rolling_restart_sleep_time].to_i)
        end
    end
    action :nothing
    subscribes :create, "ruby_block[coordinate-kafka-start]", :immediate
    #only_if { node[:kafka][:restart_failed] and
    #!process_restarted_after_failure?(node[:kafka][:restart_failed_time],"kafka.Kafka")}
end


ruby_block 'coordinate-kafka-start' do
  block do
    Chef::Log.debug 'kafka recipe to coordinate Kafka start is used'
  end
  action :nothing
end


#
# This ruby block tries to acquire a lock and if success, restart the Kafka service
#
ruby_block "acquire_lock_to_restart_kafka" do
    require 'time'
    block do
        tries = 0
        Chef::Log.info("#{node[:fqdn]}: Acquring lock at #{lock_znode_path}")
        while true
            lock = acquire_restart_lock(lock_znode_path, first_live_zk_host, node[:fqdn])
            if lock
                break
            else
                tries += 1
                if tries >= node[:kafka][:rolling_restart_max_tries].to_i
                    failure_time = Time.now().to_s
                    Chef::Log.info("Couldn't acquire lock to restart Kafka with in the #{node[:kafka][:rolling_restart_max_tries] * node[:kafka][:rolling_restart_sleep_time]} secs. Failure time is #{failure_time}")
                    Chef::Log.info("Node #{get_restart_lock_holder(lock_znode_path, first_live_zk_host)} may have died during Kafka restart.")
                    node.set[:kafka][:restart_failed] = true
                    node.set[:kafka][:restart_failed_time] = failure_time
                    node.save if !Chef::Config.solo
                    break
                end
                Chef::Log.info("Sleep for #{tries} time.")
                sleep(node[:kafka][:rolling_restart_sleep_time].to_i)
            end
        end
    end
    action :nothing
    subscribes :create, "ruby_block[handle_prev_kafka_restart_failure]", :immediate
    #subscribes :create, "ruby_block[coordinate-kafka-start]", :immediate
end

#
# If lock to restart kafka service is acquired by the node, this ruby_block executes which is primarily used to notify kafka service to restart
#
ruby_block "coordinate_kafka_restart" do
    block do
        Chef::Log.info("Kafka will be restarted in node #{node[:fqdn]}")
    end
    action :create
    only_if { my_restart_lock?(lock_znode_path, first_live_zk_host, node[:fqdn]) }
    notifies :restart, 'service[kafka]', :immediate
end

service 'kafka' do
    supports :status => true, :restart => true,:stop => true, :start => true
    action [:start, :enable]
end
    


#
# Once the Kafka service restart is complete, the following block releases the lock if the node executing is the one which holds the lock
#

ruby_block "release_kafka_restart_lock" do
    block do
        myBrokerId = `/bin/grep broker.id /etc/kafka/broker.properties | awk -F\= '{print $2}'`.strip # use 'strip' to remove the tailing `\n`
        # need to have a short sleep here, to ensure that the broker id is safely removed from "/brokers/ids" in Zookeeper.
        # Otherwise, "brokerList.include?(myBrokerId)" will return true, even though the broker has not been restarted successfully.
        sleep(5)

        wait_kafka_restart = 0
        Chef::Log.info("#{node[:hostname]}: Releasing lock at #{lock_znode_path}")
        # the only condition to release the lock is: Kafka service has been sucessfully restarted.
        # to verify above: query Zookeeper's znode "/brokers/ids" and see if the current broker id is under it.
        while true
            brokerList = `/usr/local/kafka/bin/zookeeper-shell.sh #{first_live_zk_host} ls /brokers/ids | tail -1 | sed 's;\[\|\]\|\,;;g'`.strip # use 'strip' to remove the tailing `\n`
            brokerList = brokerList.gsub!(/[\[\]]/,'').split(/\s*,\s*/)
            
            if brokerList.include?(myBrokerId)
                lock_rel = rel_restart_lock(lock_znode_path, first_live_zk_host, node[:fqdn])
                break
            else
                wait_kafka_restart += 1
                if wait_kafka_restart >= node[:kafka][:rolling_restart_max_tries].to_i
                    Chef::Log.info("Couldn't verify that Kafka is sucessfully restarted in the #{node[:kafka][:rolling_restart_max_tries] * node[:kafka][:rolling_restart_sleep_time]} secs. will go ahead and  release the lock anyway without further waiting.")
                    rel_restart_lock(lock_znode_path, first_live_zk_host, node[:fqdn])
                    break
                end
                Chef::Log.info("release_kafka_restart_lock: Sleep for #{wait_kafka_restart} time.")
                sleep(node[:kafka][:rolling_restart_sleep_time].to_i)
            end
        end
    end
    action :create
    only_if { my_restart_lock?(lock_znode_path, first_live_zk_host, node[:fqdn]) }
end
