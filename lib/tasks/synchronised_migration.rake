require 'synchronised_migration/main'

namespace :synchronised_migration do
  task :execute do
    result = SynchronisedMigration::Main.call
    next if result.success?
    fail result.error
  end
end
