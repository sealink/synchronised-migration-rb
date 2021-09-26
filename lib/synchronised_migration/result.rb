require "synchronised_migration"

module SynchronisedMigration
  MIGRATION_SUCCESS = 0
  PREVIOUS_SUCCESS = 1
  PREVIOUS_FAILED = 2
  MIGRATION_FAILED = 3

  PREVIOUS_FAILED_MSG = "Halting the script because the previous migration failed."
  MIGRATION_FAILED_MSG = "Migration command failed."

  class Result
    attr_reader :code

    def initialize(code)
      @code = code
    end

    def succesful?
      [MIGRATION_SUCCESS, PREVIOUS_SUCCESS].include?(code)
    end

    def failure?
      !succesful?
    end

    def error_msg
      case code
      when MIGRATION_FAILED
        MIGRATION_FAILED_MSG
      when PREVIOUS_FAILED
        PREVIOUS_FAILED_MSG
      end
    end

    def self.ok
      new(MIGRATION_SUCCESS)
    end

    def self.migration_already_completed
      new(PREVIOUS_SUCCESS)
    end

    def self.previous_migration_failed
      new(PREVIOUS_FAILED)
    end

    def self.migration_failed
      new(MIGRATION_FAILED)
    end
  end
end
