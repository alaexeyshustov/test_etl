class Broker

  @objects = {}

  def self.new(topic)

    unless @objects[topic]
      @objects[topic] = super
    end

    @objects[topic]
  end

  def initialize(*_args)
    @subscribers = []
  end

  def subscribe(channel)
    @subscribers << channel
  end

  def publish(message)
    @subscribers.each do |channel|
      channel.notify(message)
    end
  end

end