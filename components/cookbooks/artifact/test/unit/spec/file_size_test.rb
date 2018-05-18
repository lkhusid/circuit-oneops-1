# Object for holding testing data
class File_size_test
  MIN_SIZE   = 2097152
  MAX_PARTS  = 10
  CHUNK_SIZE = 1048576

  attr_reader :file_size
  attr_reader :parts
  attr_reader :parts_size_sum
  attr_reader :parts_are_same

  def initialize(max_size, lib)
    # Instance variables
    @file_size = Random.new.rand(MIN_SIZE..max_size)
    @parts = lib.calculate_parts(@file_size, MAX_PARTS, CHUNK_SIZE)
    @parts_size_sum = size_sum(@parts)
    @parts_are_same = size_sameness?(@parts)
  end

  def size_sum(parts)
    sum_of_sizes = 0
    parts.each do |part|
      sum_of_sizes = sum_of_sizes + part['size']
    end
    return sum_of_sizes
  end

  def size_sameness?(parts)
    if parts.length >= 3
      previous = parts.first['size'].to_i
      parts.each do |part|
        if previous != part['size'].to_i && part != parts.last
          return false
        end
        previous = part['size'].to_i
      end
    end
    return true
  end

  private :size_sum, :size_sameness?

end