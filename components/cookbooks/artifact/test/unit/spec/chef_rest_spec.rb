# Unit tests for circuit-oneops-1/components/cookbooks/artifact/libraries/chef_rest.rb


require '../../libraries/chef_rest'
require 'file_size_test'

describe Chef::REST do
  lib = Chef::REST.new

  #------------------- Test for calculate_parts method -------------------#
  # Max file size
  max_size = 1000000000000

  # Number of sizes to test. Actual examples will be 3 times this number.
  number_of_tests = 50

  array_of_tests = Array.new(number_of_tests)
  for i in 0..number_of_tests
    array_of_tests[i] = File_size_test.new(max_size, lib)
  end

  context "given file sizes from 2097152 to #{max_size}\n" do
    describe "  calculate_parts for #{number_of_tests} file sizes\n" do
      array_of_tests.each do |test|
        context "   given a file of size #{test.file_size}bytes\n" do
          it "     all parts except last must have equal size\n" do
            expect(test.parts_are_same).to eql(true)
          end
          it "     sum of parts must equal #{test.file_size}\n" do
            expect(test.parts_size_sum).to eql(test.file_size)
          end

          it "     last part must end at #{test.file_size-1}\n" do
            expect(test.parts.last['end']).to eql(test.file_size-1)
          end
        end
      end
    end
  end
  #------------------- Test for calculate_parts method -------------------#
  
end

