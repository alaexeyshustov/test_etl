module RedisConnection

  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods

    def config
      unless @config
        cfg = YAML.load(File.read(Rails.root.join('config', 'redis.yml')))
        @config = {host: cfg['host'], port: cfg['port'], db: cfg['db'], password: cfg['password'] }
      end
      @config
    end

    def redis
      unless @connection
        cfg = config
        # cfg[:logger] = Rails.logger
        @connection = Redis.new(cfg )
      end
      @connection
    end

    def redis_key_lock(key, &block)
      lock_timeout = true

      50.times do
        if redis.setnx(key, 'locked')
          lock_timeout = false
          break
        end
        sleep 0.2
      end

      raise "Redis lock timeout for key #{key}" if lock_timeout

      begin
        yield(block)
      ensure
        redis.del(key)
      end
    end


  end

  extend ClassMethods

end
