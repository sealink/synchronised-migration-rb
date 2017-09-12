class SynchronisedMigration::Railtie < Rails::Railtie
  rake_tasks do
    load 'tasks/synchronised_migration.rake'
  end
end
