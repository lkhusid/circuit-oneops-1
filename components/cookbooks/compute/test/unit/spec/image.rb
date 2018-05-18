# Object for holding testing data
class Image
  attr_reader :name
  attr_reader :id

  def initialize(name, id)
    # Instance variables
    @name = name
    @id = id
  end
end