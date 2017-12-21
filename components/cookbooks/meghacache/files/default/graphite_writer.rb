require 'json'
require 'net/http'
require 'socket'
require 'logger'
require 'uri'
require '/opt/memcached/lib/memcache_stats'

class GraphiteWriter

  attr_accessor :prefix, :graphite_hosts, :environment,
                :cloudname, :tcp_sockets, :graphite_logfiles_path,
                :rotate,  :log_size, :logger, :metric_name_prefix,
                :cloud_level_prefix

  CONST_MAX_LOG_FILE_ROTATION_DAYS = 10
  CONST_MAX_LOG_FILE_SIZE = 10 * 1024 * 1024
  CONST_METRIC_NAME_CONF_POOL_SIZE = 'configured_pool_size'

  def initialize(prefix, graphite_hosts, environment, cloudname, graphite_logfiles_path, metric_name_prefix = nil, rotate = nil, log_size = nil)

    @graphite_hosts = graphite_hosts
    @environment = environment
    @cloudname = cloudname
    @graphite_logfiles_path = graphite_logfiles_path
    @rotate = rotate
    @log_size = log_size
    @metric_name_prefix = metric_name_prefix
    @cloud_level_prefix = "#{prefix}.#{@environment}.meghacache.#{@cloudname}"

    host = `hostname`.downcase.chop
    if (@metric_name_prefix != nil)
        @prefix = "#{@cloud_level_prefix}.nodes.#{host.gsub('.','-')}.#{@metric_name_prefix}"
    else
        @prefix = "#{@cloud_level_prefix}.nodes.#{host.gsub('.','-')}."
    end

    #Use defaults if log file rotation isn't set up
    if (rotate == nil || rotate == 0)
      rotate = CONST_MAX_LOG_FILE_ROTATION_DAYS
    end
    @rotate = rotate

    #Use defaults if log file size isn't set up
    if (log_size == nil || log_size == 0)
      log_size =  CONST_MAX_LOG_FILE_SIZE
    end
    @log_size = log_size
    @logger = Logger.new(@graphite_logfiles_path, @rotate,  @log_size)
    @logger.level = Logger::ERROR
  end

  #Opens tcp sockets to all graphite servers on the specified port#
  def open_tcp_sockets()
    logger.debug "open_tcp_sockets:start: graphite host list = #{@graphite_hosts}"

    if (@graphite_hosts.length > 0)

      @tcp_sockets = Array.new
      graphite_hosts.each do |graphite_host|
        begin
          graphite_server = graphite_host.split(':')[0]
          port = graphite_host.split(':')[1]
          tcp_socket = TCPSocket.new(graphite_server, port)
          @tcp_sockets.insert(-1, tcp_socket)
        rescue Exception => e
          logger.error "open_tcp_sockets:exception: graphite host = #{graphite_host} #{e}"
        end
      end

    end

    logger.debug 'open_tcp_sockets:end: Completed'

  end


  #Close tcp sockets to all graphite servers
  def close_tcp_sockets()
    logger.debug "close_tcp_sockets:start: tcp sockets list = #{@tcp_sockets}"

    if (@tcp_sockets.length > 0)

      @tcp_sockets.each do |tcp_socket|
        begin
          tcp_socket.close
        rescue Exception => e
          logger.error "close_tcp_sockets:exception: #{e}"
        end
      end

    end

    logger.debug 'close_tcp_sockets:end: Completed'

  end


  #Iterates through a list of graphite hosts, opens up a TCP connection and
  #writes the metrics out to the graphite server
  def write_to_graphite(stats_hash, time = Time.now)
    logger.debug "write_to_graphite:start: #{stats_hash}"

    if (@tcp_sockets.length > 0)

      @tcp_sockets.each do |tcp_socket|

        stats_hash['stats'].each_pair do |key, value|
          begin

            if key == CONST_METRIC_NAME_CONF_POOL_SIZE
                metric_key = @cloud_level_prefix + '.' + key
            else
                metric_key = @prefix + key
            end

            logger.debug "write_to_graphite:start: key = #{metric_key}, value = #{value}, time = #{time.to_i}"
            tcp_socket.write("#{metric_key} #{value.to_f} #{time.to_i}\n")

          rescue Exception => e
            logger.error "write_to_graphite:exception: #{e}"
          end

        end

        logger.debug 'delta processing'
        time_elapsed = stats_hash['delta']['time'].to_f
        stats_hash['delta'].select{|name, value| value.to_f >= 0 && name != 'time'}.each_pair do |key, value|
          begin
            metric_key = @prefix + key + '_per_sec'
            metric_value = (value.to_f / time_elapsed).round(3).to_s
            logger.debug "write_to_graphite:start: key = #{metric_key}, value = #{metric_value}, time = #{time.to_i}"
            tcp_socket.write("#{metric_key} #{metric_value} #{time.to_i}\n")

          rescue Exception => e
            logger.error "write_to_graphite:exception: #{e}"
          end

        end


      end

    end

    logger.debug 'write_to_graphite:end: Completed'

  end

end
