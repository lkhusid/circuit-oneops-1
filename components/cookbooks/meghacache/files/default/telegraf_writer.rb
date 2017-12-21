require 'logger'

class TelegrafWriter

  attr_accessor :name, :rotate,  :log_size, :logger, :stats_log

  CONST_MAX_LOG_FILE_ROTATION_DAYS = 10
  CONST_MAX_LOG_FILE_SIZE = 10 * 1024 * 1024
  MISSING_FIELD_VALUE = 0

  def initialize(name, logfiles_path, rotate = nil, log_size = nil)

    @name = name
    @rotate = rotate
    @log_size = log_size
    @logfiles_path = logfiles_path

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
    @logger = Logger.new(@logfiles_path, @rotate,  @log_size)
    @logger.level = Logger::ERROR
    
    @stats_log = Logger.new('/opt/meghacache/log/telegraf/stats.log', @rotate,  @log_size)
    @stats_log.formatter = proc { |_s, _d, _p, msg| "#{msg}\n" }
      
  end

  def write_influx(stats_hash, time = Time.now)
    logger.debug "write_influx:start: #{stats_hash}"

    fields_array = []
    stats_hash['stats'].each_pair do |key, value|

      logger.debug "write_influx:start: key = #{key}, value = #{value}"

      fields_array.push("#{key}=#{value.nil? ? MISSING_FIELD_VALUE : value}");
    end

    logger.debug 'delta processing'
    
    time_elapsed = stats_hash['delta']['time'].to_f
    stats_hash['delta'].select{|name, value| value.to_f >= 0 && name != 'time'}.each_pair do |key, value|
      metric_key = key + '_per_sec'
      metric_value = (value.to_f / time_elapsed).round(3).to_s
      
      logger.debug "write_influx:start: key = #{metric_key}, value = #{metric_value}"

      fields_array.push("#{metric_key}=#{metric_value}");
    end

    @stats_log.info("#{@name} #{fields_array.join(',')} #{time.to_i}000000000")
    
    logger.debug 'write_influx:end: Completed'

  end

end
