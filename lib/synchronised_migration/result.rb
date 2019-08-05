require 'synchronised_migration'

class SynchronisedMigration::Result
  attr_accessor :error

  def initialize(error = nil)
    @error = error
  end

  def success?
    error.nil?
  end

  def self.ok
    self.new
  end

  def self.fail(error)
    self.new error
  end
end
