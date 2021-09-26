module SynchronisedMigration
  class Configuration
    attr_accessor :redis_uri
    attr_accessor :command
    attr_accessor :application
    attr_accessor :debug
    attr_accessor :version

    def self.from_cli(options)
      config_yml = YAML.load_file(options[:config]).transform_keys(&:to_sym).to_h
      new(config_yml.merge(options.compact))
    end

    def initialize(options = {})
      @application = options.fetch(:application, nil)
      @version = options.fetch(:version, nil)
      @redis_uri = options.fetch(:redis_uri, "redis://127.0.0.1:6379/0")
      @debug = options.fetch(:debug, false)
      @command = options.fetch(:command, "bin/launch/migrate")
      @timeout_milliseconds = options.fetch(:timeout_milliseconds, 3_600_000).to_i
      @retry_delay_milliseconds = options.fetch(:retry_delay_milliseconds, 3000).to_i

      raise OptionParser::InvalidArgument, "Application must be configured" if @application.nil?
    end

    def timeout_milliseconds
      @timeout_milliseconds.to_i
    end

    def retry_delay_milliseconds
      @retry_delay_milliseconds.to_i
    end

    def debug?
      debug
    end

    def success_key
      "migration-success-#{application}-#{version}"
    end

    def fail_key
      "migration-failed-#{application}"
    end

    def lock_key
      "migration-lock-#{application}"
    end
  end
end
