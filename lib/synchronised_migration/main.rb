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
    done_or_execute
  end

  private

  def done_or_execute
    return Result.ok if previous_success?
    result = lock_and_execute
    mark_successful if result.success?
    result
  end

  def lock_and_execute
    redlock.lock! lock_key, timeout do
      execute
    end
  end

  def execute
    return Result.fail 'Halting the script because the previous migration failed.' if previous_failed?
    mark_failed
    migrate
    return Result.fail 'Migration failed.' if migration_failed?
    remove_fail_marker
    return Result.ok
  end

  def previous_success?
    return false if !success_key
    value = redis.get(success_key)
    not value.nil? and not value.empty?
  end

  def mark_successful
    if success_key
      redis.set success_key, Time.now.to_i, ttl: 30.days
    end
  end

  def previous_failed?
    value = redis.get(fail_key)
    not value.nil? and not value.empty?
  end

  def mark_failed
    redis.set fail_key, Time.now.to_i, ttl: 1.hour
  end

  def remove_fail_marker
    redis.del fail_key
  end

  def migrate
    return Kernel.system target_command unless with_clean_env?
    Bundler.with_original_env do
      Kernel.system target_command
    end
  end

  def with_clean_env?
    not ENV.fetch('WITH_CLEAN_BUNDLER_ENV', '').empty?
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
      SynchronisedMigration.redis_config.host,
      SynchronisedMigration.redis_config.port,
      SynchronisedMigration.redis_config.db
    )
  end

  def timeout
    ENV.fetch('REDLOCK_TIMEOUT_MS', 3_600_000).to_i
  end

  def retry_delay
    ENV.fetch('REDLOCK_RETRY_DELAY_MS', 3000).to_i
  end

  def retry_count
    timeout / retry_delay
  end

  def lock_key
    ENV.fetch 'REDLOCK_LOCK_KEY', 'migration-in-progress'
  end

  def fail_key
    ENV.fetch 'REDLOCK_FAIL_KEY', 'migration-failed' + version_suffix
  end

  def success_key
    return false if version_suffix.empty?
    'migration-success' + version_suffix
  end

  def version_suffix
    suffix = ENV.fetch 'REDLOCK_VERSION_SUFFIX', false
    suffix ? '-' + suffix : ''
  end
end
