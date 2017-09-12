require 'synchronised_migration'

class SynchronisedMigration::Result
  attr_accessor :error

  def initialize(error = nil)
    @error = error
  end

  def success?
    error.nil?
  end
end
