broker = Broker.new('events')
channel = NetcatChannel.new(BatchQueue.new)

broker.subscribe(channel)