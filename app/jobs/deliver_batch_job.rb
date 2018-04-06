class DeliverBatchJob < ActiveJob::Base
  queue_as :default

  def perform(messages)
    if messages.is_a?(Array)
      NetcatChannel.deliver(messages)

    elsif messages.is_a?(String)
      queue = messages.constantize.new
      messages = queue.clear_queue(true)

      NetcatChannel.deliver(messages)
    end

  end

end