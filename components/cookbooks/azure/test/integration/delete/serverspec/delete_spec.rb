require "/opt/oneops/inductor/circuit-oneops-1/components/spec_helper.rb"

#run the tests
tsts = File.expand_path("tests", File.dirname(__FILE__))
Dir.glob("#{tsts}/*.rb").each {|tst| require tst}