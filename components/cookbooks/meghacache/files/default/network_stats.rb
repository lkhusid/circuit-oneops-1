#!/usr/bin/env ruby

require 'pstore'

class NetworkStats
    attr_accessor :stats_path
    attr_accessor :pstore_file

    def initialize()
        @stats_path = "/opt/memcached/stats"
        @pstore_file = "system.pstore"
    end

    def get_stats(delta_stats = [])
        pstore_file_path = "#{@stats_path}/#{@pstore_file}"
        stat_store = PStore.new(pstore_file_path, true)
        stat_store.ultra_safe = true
        old_stats = {}
        begin
            stat_store.transaction(true) do
                if stat_store['stats'].nil?
                    old_stats = {}
                else
                    old_stats = stat_store['stats']
                end
            end
        rescue => e
           puts "Deleting corrupt pstore file #{pstore_file_path}"
           File.delete("#{pstore_file_path}") 
           puts e.backtrace
           raise #reraise
        end

        stats_hash = {}

        stats_hash['time'] = Time.now.to_i

        interface=`ip route list|grep default |awk '{print $5}'`.chomp
        if interface.nil? || interface.empty?
            raise "Unable to determine default network interface"
        end
        stats_dir="/sys/class/net/#{interface}/statistics"
        delta_stats.each do |name|
            stat_file = "#{stats_dir}/#{name}" 
            if File.exist?(stat_file)
                stats_hash[name] = File.read(stat_file).chomp
            else
                puts "File #{stat_file} does not exist"
            end
        end
      
        return_stats = {
            "stats" => {},
            "delta" => get_deltas(stats_hash, old_stats, delta_stats)
        }
        stat_store.transaction do
            stat_store['stats'] = stats_hash
        end
        return_stats
    end

    def get_deltas(stats_hash, old_stats, delta_stats)
        # Always provide the time delta, no matter what else is requested.
        delta_hash = {
            'time' => stats_hash['time'].to_i - old_stats['time'].to_i
        }
        delta_stats.each {|stat_name|
            if stats_hash.has_key? stat_name
                delta_val = stats_hash[stat_name].to_i - old_stats[stat_name].to_i
                delta_hash[stat_name] = delta_val
            end
        }
        return delta_hash
    end
end
