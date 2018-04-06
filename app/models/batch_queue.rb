require 'sidekiq/api'

class BatchQueue
  include RedisConnection

  BATCH_SIZE    = 10
  BATCH_TIMEOUT = 10.minutes

  KEY       = 'events_queue'
  LOCK_KEY  = 'events_queue_lock'
  TIMER_KEY = 'events_queue_timer'

  def add(event)
    self.class.redis_key_lock(LOCK_KEY) do

      self.class.redis.rpush(KEY, event.to_message)
      size = self.class.redis.llen(KEY)

      if size == BATCH_SIZE
        messages = clear_queue
        stop_timer
        send_now(messages)
      elsif size == 1
        start_timer
      end

    end
  end

  def clear_queue(lock = false)
    messages = []

    if lock
      self.class.redis_key_lock(LOCK_KEY) do
        messages = clear
      end
    else
      messages = clear
    end

    messages
  end

  private

  def clear
    messages = self.class.redis.lrange(KEY, 0, -1)
    self.class.redis.del(KEY)
    messages
  end

  def send_now(messages)
    DeliverBatchJob.perform_later(messages)
  end

  def start_timer
    job = DeliverBatchJob.set(wait: BATCH_TIMEOUT).perform_later(self.class.to_s)
    self.class.redis.set(TIMER_KEY, job.job_id)
  end

  def stop_timer
    job_id = self.class.redis.get(TIMER_KEY)
    self.class.redis.del(TIMER_KEY)

    ss = Sidekiq::ScheduledSet.new
    job = ss.find {|j| j.args.first['job_id'] == job_id}
    job.delete
  end

end