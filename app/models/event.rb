class Event
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def to_message
    name
  end

end