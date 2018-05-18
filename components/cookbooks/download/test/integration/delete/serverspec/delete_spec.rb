is_windows = ENV['OS'] == 'Windows_NT'

CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops"
require "#{CIRCUIT_PATH}/circuit-oneops-1/components/spec_helper.rb"

puts "Download delete kitchen-test called, temporary placeholder recipe."