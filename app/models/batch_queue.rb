require 'sidekiq/api'

class BatchQueue
  include RedisConnection

  BATCH_SIZE    = 10
  BATCH_TIMEOUT = 10.minutes

  KEY       = 'events_queue'
  LOCK_KEY  = 'events_queue_lock'
  TIMER_KEY = 'events_queue_timer'

  def add_with_lock(event)
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

  def add_with_transaction(event)
    result = self.class.redis_transaction(KEY, ->(connection) {connection.llen(KEY)}) do |multi, size|

      if size == BATCH_SIZE - 1
        multi.lrange(KEY, 0, -1)
        multi.del(KEY)
      else
        multi.rpush(KEY, event.to_message)
      end
    end

    if result.first.is_a?(Array)
      messages = result.first + [event.to_message]
      stop_timer
      send_now(messages)
    elsif result.first.is_a?(Integer) && result.first == 1
      start_timer
    end

  end

  def add_with_lua(event)
    result = self.class.run_lua(lua_script, KEY, BATCH_SIZE, event.to_message)

    if result.is_a?(Array)
      stop_timer
      send_now(result)
    elsif result.is_a?(Integer) && result == 1
      start_timer
    end
  end

  alias add add_with_lua

  def clear_queue
    result = self.class.redis.multi do |multi|
      multi.lrange(KEY, 0, -1)
      multi.del(KEY)
    end

    result.first
  end

  private

  def send_now(messages)
    DeliverBatchJob.perform_later(messages)
  end

  def start_timer
    job = DeliverBatchJob.set(wait: BATCH_TIMEOUT).perform_later(self.class.to_s)
    unless self.class.redis.setnx(TIMER_KEY, job.job_id)
      delete_job_by_id(job.job_id)
    end
  end

  def stop_timer
    result = self.class.redis.multi do |multi|
      multi.get(TIMER_KEY)
      multi.del(TIMER_KEY)
    end

    job_id = result.first
    Rails.logger.warn "Timer stopped #{job_id}"
    delete_job_by_id(job_id)
  end

  def delete_job_by_id(job_id)
    ss = Sidekiq::ScheduledSet.new
    job = ss.find {|j| j.args.first['job_id'] == job_id}
    job.delete if job
  end

  def lua_script
    <<-LUA
        local key         = ARGV[1]
        local batch_size  = tonumber(ARGV[2])
        local message     = ARGV[3]

        redis.pcall("rpush", key, message);
        local size = redis.pcall("llen", key);

        if size == batch_size then
          local messages = redis.pcall("lrange", key, 0, -1);
          redis.pcall("del", key)
          return messages
        else
          return size
        end
    LUA
  end


end