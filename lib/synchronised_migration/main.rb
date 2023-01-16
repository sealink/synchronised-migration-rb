module SynchronisedMigration
  class Main
    FAIL_TIMEOUT = 3600 # 1 Hour
    SUCCESS_TIMEOUT = 3600 * 24 * 30 # 30 dyas

    def initialize(config)
      @config = config
    end

    def call
      return Result.migration_already_completed if migration_already_completed?

      lock_and_execute
    end

    private

    def lock_and_execute
      client = Redlock::Client.new(
        [@config.redis_uri], {
          retry_count: retry_count,
          retry_delay: @config.retry_delay_milliseconds
        }
      )
      client.lock!(@config.lock_key, @config.timeout_milliseconds) do
        execute_within_lock
      end
    end

    def execute_within_lock
      return Result.ok if migration_already_completed?
      return Result.previous_migration_failed if previous_failed?
      mark_failed
      migration_success = migrate
      return Result.migration_failed unless migration_success
      mark_successful
      remove_fail_marker
      Result.ok
    end

    def migration_already_completed?
      redis.exists?(@config.success_key)
    end

    def mark_successful
      success_obj = {application: @config.application, version: @config.version, command: @config.command, timestamp: timestamp}.to_json
      redis.set(@config.success_key, success_obj, ex: SUCCESS_TIMEOUT)
    end

    def previous_failed?
      redis.exists?(@config.fail_key)
    end

    def mark_failed
      redis.set(@config.fail_key, timestamp, ex: FAIL_TIMEOUT)
    end

    def remove_fail_marker
      redis.del(@config.fail_key)
    end

    def migrate
      Kernel.system @config.command
      $?.success?
    end

    def redis
      @redis ||= begin
        redis_opts = {url: @config.redis_uri}

        Redis.new(redis_opts)
      end
    end

    def timestamp
      Time.now.to_i
    end

    def retry_count
      @config.timeout_milliseconds / @config.retry_delay_milliseconds
    end
  end
end
