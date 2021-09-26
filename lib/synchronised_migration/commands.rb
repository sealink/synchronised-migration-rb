# frozen_string_literal: true

module SynchronisedMigration
  module Commands
    extend Dry::CLI::Registry

    class Migrate < Dry::CLI::Command
      desc "Run the provided command in a migration lock"

      option :config, type: :string, required: true, desc: "Configuration file location"
      option :version, type: :string, required: true, desc: "Version we are migrating to"
      option :application, type: :string, desc: "Application we are migrating"
      option :redis_uri, type: :string, desc: "Redis Server URI"
      option :debug, type: :boolean, desc: "Enable additional debugging output"

      def call(**options)
        abort "Config location must be provided" if options[:config].nil?
        abort "Version must be provided" if options[:version].nil?

        config = SynchronisedMigration::Configuration.from_cli(options)
        result = SynchronisedMigration::Main.new(config).call

        abort(result.error_msg) if result.failure?
        $stdout.puts "Complete!"
      end
    end

    class Clear < Dry::CLI::Command
      desc "Clear the migration keys"

      option :config, type: :string, required: true, desc: "Configuration file"
      option :version, type: :string, required: true, desc: "Version we are migrating to"
      option :application, type: :string, desc: "Application we are migrating"
      option :redis_uri, type: :string, desc: "Redis Server URI"
      option :debug, type: :boolean, desc: "Enable additional debugging output"
      option :all, type: :boolean, default: false, desc: "Clear all keys including success"

      def call(**options)
        abort "Config location must be provided" if options[:config].nil?

        config = SynchronisedMigration::Configuration.from_cli(options)

        redis_opts = {url: config.redis_uri}
        redis_opts[:logger] = Logger.new($stdout) if config.debug?

        redis = Redis.new(redis_opts)
        redis.del(config.fail_key)

        if options[:all]
          abort "Version must be provided" if options[:version].nil?
          redis.del(config.success_key)
          redis.del(config.lock_key)
        end

        $stdout.puts "Complete!"
      end
    end

    class Status < Dry::CLI::Command
      desc "Shows the current status the redis failure if any"

      option :config, type: :string, required: true, desc: "Configuration file"
      option :version, type: :string, required: true, desc: "Version we are migrating to"
      option :application, type: :string, desc: "Application we are migrating"
      option :redis_uri, type: :string, desc: "Redis Server URI"
      option :debug, type: :boolean, desc: "Enable additional debugging output"

      def call(**options)
        abort "Config location must be provided" if options[:config].nil?
        abort "Version must be provided" if options[:version].nil?

        config = SynchronisedMigration::Configuration.from_cli(options)

        redis_opts = {url: config.redis_uri}
        redis_opts[:logger] = Logger.new($stdout) if config.debug?
        redis = Redis.new(redis_opts)

        rows = []
        fail_key = config.fail_key
        rows << if redis.exists?(fail_key)
          [fail_key, "true", "Failed Migration"]
        else
          [fail_key, "false", nil]
        end

        success_key = config.success_key
        rows << if redis.exists?(success_key)
          [success_key, "true", "Succesfully Migrated"]
        else
          [success_key, "false", nil]
        end

        lock_key = config.lock_key
        rows << if redis.exists?(lock_key)
          [lock_key, "true", "Running Migration"]
        else
          [lock_key, "false", nil]
        end

        table = TTY::Table.new(["key", "status", "message"], rows)
        $stdout.puts table.render(:ascii)
      end
    end

    register "migrate", Migrate
    register "clear", Clear
    register "status", Status
  end
end
