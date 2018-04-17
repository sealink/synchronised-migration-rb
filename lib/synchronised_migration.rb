module SynchronisedMigration
  class << self
    attr_accessor :redis_config
  end

  def self.configure
    self.redis_config ||= Configuration.new
    yield(redis_config)
  end

  class Configuration
    attr_accessor :host, :port, :db

    def initialize
      @host = ''
      @port = 0
      @db   = 0
    end
  end
end

require 'synchronised_migration/railtie' if defined?(Rails)
