#!/usr/bin/env ruby

require 'socket'
require 'pstore'

class MemcacheStats
    attr_accessor :hostname
    attr_accessor :port
    attr_accessor :stats_path
    attr_accessor :pstore_file

    def initialize(host = 'localhost', port_num = 11211)
        @hostname = host
        @port = port_num
        @stats_path = "/opt/memcached/stats"
        @pstore_file = "memcached.pstore"
        BasicSocket.do_not_reverse_lookup = true
    end

    def get_stats(stat_names = [], delta_stats = [])
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
        begin
            s = TCPSocket.new @hostname, @port
        rescue SystemCallError
            raise MemcacheConnectionError.new("Cannot connect to #{@hostname}:#{@port}", hostname, port)
        end

        s.puts 'stats'
        s.puts 'quit'
        stats_hash = {}
        s.each { |line|
            (header, stat, value) = line.split(' ')
            stats_hash[stat] = value if header == 'STAT'
        }
        s.close
        stat_names = stats_hash.keys if stat_names.nil? || stat_names.empty?
        return_stats = {
            "stats" => stats_hash.select {|key, v| stat_names.include?(key)},
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

class MemcacheConnectionError < IOError
    attr_accessor :msg
    attr_accessor :host
    attr_accessor :port

    def initialize(msg, host, port)
        @msg = msg
        @host = host
        @port = port
    end

    def to_s
        @msg
    end
end
