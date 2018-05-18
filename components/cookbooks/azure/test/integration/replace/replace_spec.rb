require '/opt/oneops/inductor/circuit-oneops-1/components/spec_helper.rb'

#run the tests
tests = File.expand_path('tests', File.dirname(__FILE__))
Dir.glob("#{tests}/*.rb").each {|test| require test}
