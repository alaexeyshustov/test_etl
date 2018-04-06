require 'httparty'

class NetcatChannel < AbstractChannel

  attr_reader :queue

  def initialize(queue)
    @queue = queue
  end

  def notify(message)
    queue.add(message)
  end

  def self.deliver(messages)
    HTTParty.post(url,
                  body: messages.to_s,
                  headers: { 'Content-Type' => 'text/plain' })
  end

  def self.url
    unless @url
      cfg = YAML.load(File.read(Rails.root.join('config', 'netcat.yml')))
      @url = "http://#{cfg['host']}:#{cfg['port']}"
    end

    @url
  end

end
