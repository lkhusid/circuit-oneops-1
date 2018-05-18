#Execute add_spec.rb
spec_file =  File.join(
  File.expand_path('../../', File.dirname(__FILE__)),
  'add/serverspec',
  'add_spec.rb'
)

require spec_file
