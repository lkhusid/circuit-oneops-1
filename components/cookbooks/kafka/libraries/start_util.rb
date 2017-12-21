module Kafka
    
  module StartUtil
  
  # Check if the Kafka is running, allow #seconds to start running
  def kafka_running(seconds=120)
    begin
      Timeout::timeout(seconds) do
      running = false
      while !running do
        cmd = "service kafka status 2>&1"
        Chef::Log.info(cmd)
        result  = `#{cmd}`
        if $? == 0
          running = true
          break
        end
        sleep 5
        end
        return running
      end
      rescue Timeout::Error
      return false
    end
  end
    
  # check if the port is open
  def port_open?(ip, port)
    begin
      cmd = "service kafka status 2>&1"
      result  = `#{cmd}`
      if $? == 0
        Chef::Log.info("Check if port #{port} open on #{ip}")
        TCPSocket.new(ip, port).close
        return true
      else
        puts "***FAULT:FATAL=Kafka isn't running on #{ip}"
        e = Exception.new("no backtrace")
        e.set_backtrace("")
        raise e
      end
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
      sleep 5
      retry
    end
  end

  def ensureBrokerIDInZK
    require 'rubygems'
    require 'zookeeper'
    begin
      zk_connect_url=`/bin/grep zookeeper.connect= /etc/kafka/server.properties | awk -F\= '{print $2}'`.strip
      myhostname = `hostname -f`.strip
      zkClient = Zookeeper.new(zk_connect_url)
      ret = zkClient.get(:path => '/host_brokerid_mappings')
      if ret[:rc] == -101
        zkClient.create(:path => '/host_brokerid_mappings')
      end
      ret = zkClient.get(:path => "/host_brokerid_mappings/#{myhostname}")
      brokerid = ret[:data]
      if brokerid.nil? && ret[:rc] == -101
        brokerid = `/bin/grep broker.id /etc/kafka/broker.properties | awk -F\= '{print $2}'`.strip
        ret = zkClient.create(:path => "/host_brokerid_mappings/#{myhostname}", :data => "#{brokerid}")
        if ret[:rc] != 0 || ret[:data] != "#{brokerid}"
          # we hope next deployment will persist the mapping, so we do not quit here.
          Chef::Log.error("problem saving brokerid to zookeeper for #{myhostname} brokerid #{brokerid}")
        end
      end
     ensure
      if !zkClient.nil?
        zkClient.close() unless zkClient.closed?
      end
    end
  end

  end
end