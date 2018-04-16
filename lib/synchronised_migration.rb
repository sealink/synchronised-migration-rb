module SynchronisedMigration
  def self.redis_config=(config)
    @redis_config = config
  end

  def self.redis_config
    @redis_config
  end
end

require 'synchronised_migration/railtie' if defined?(Rails)
