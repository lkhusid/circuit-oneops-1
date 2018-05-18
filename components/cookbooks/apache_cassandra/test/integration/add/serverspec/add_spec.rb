is_windows = ENV['OS'] == 'Windows_NT'
CIRCUIT_PATH = "#{is_windows ? 'C:/Cygwin64' : ''}/home/oneops/circuit-oneops-1"
COOKBOOKS_PATH="#{CIRCUIT_PATH}/components/cookbooks"

require "#{CIRCUIT_PATH}/components/spec_helper.rb"

#run the tests
tsts = File.expand_path("tests", File.dirname(__FILE__))
Dir.glob("#{tsts}/*.rb").each {|tst| require tst}

