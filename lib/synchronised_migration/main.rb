require 'synchronised_migration'
require 'synchronised_migration/result'
require 'redis'
require 'redlock'
require 'singleton'

class SynchronisedMigration::Main
  include Singleton

  Result = SynchronisedMigration::Result

  class << self
    extend Forwardable
    def_delegators :instance, :call
  end

  def call
    lock_and_execute
  end

  private

  def lock_and_execute
    redlock.lock! lock_key, timeout do
      execute
    end
  end

  def execute
    return Result.new 'Halting the script because the previous migration failed.' if previous_failed?
    mark_failed
    migrate
    return Result.new 'Migration failed.' if migration_failed?
    remove_fail_marker
    Result.new
  end

  def previous_failed?
    value = redis.get(fail_key)
    not value.nil? and not value.empty?
  end

  def mark_failed
    redis.set fail_key, 1
  end

  def remove_fail_marker
    redis.del fail_key
  end

  def migrate
    Kernel.system target_command
  end

  def migration_failed?
    not $?.success?
  end

  def target_command
    ENV.fetch 'SYNCHRONISED_COMMAND', 'bin/launch/migrate'
  end

  def redis
    @redis ||= Redis.new(url: redis_url)
  end

  def redlock
    @redlock ||= Redlock::Client.new(
      [ redis_url ], {
        retry_count: retry_count,
        retry_delay: retry_delay
      }
    )
  end

  def redis_url
    sprintf(
      'redis://%s:%s/%s',
      RedisConfig.get[:host],
      RedisConfig.get[:port],
      RedisConfig.get[:db]
    )
  end

  def timeout
    ENV.fetch('REDLOCK_TIMEOUT_MS', 3_600_000).to_i
  end

  def retry_delay
    ENV.fetch('REDLOCK_RETRY_DELAY_MS', 200).to_i
  end

  def retry_count
    timeout / retry_delay
  end

  def lock_key
    ENV.fetch 'REDLOCK_LOCK_KEY', 'migration-in-progress'
  end

  def fail_key
    ENV.fetch 'REDLOCK_FAIL_KEY', 'migration-failed'
  end
end
