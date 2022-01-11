require_relative "lib/synchronised_migration/version"

Gem::Specification.new do |spec|
  spec.name = "synchronised_migration"
  spec.version = SynchronisedMigration::VERSION
  spec.authors = ["Alvin Yim", "Stefan Cooper"]
  spec.email = "support@travellink.com.au"
  spec.description = "Use Redis to record the data migration status"
  spec.summary = "For deploying to multiple instances simultaneously"
  spec.homepage = "https://github.com/sealink/synchronised-migration-rb"

  spec.files = Dir["CHANGELOG.md", "README.md", "lib/**/*"]
  spec.bindir = "exe"
  spec.executables = ["synchronised-migration"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.6.0"

  spec.add_dependency "redlock", ">= 0.2"
  spec.add_dependency "redis", ">= 4.2.1"
  spec.add_dependency "dry-cli"
  spec.add_dependency "tty-table"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "coverage-kit"
  spec.add_development_dependency "rspec", ">= 3.6"
  spec.add_development_dependency "pry-byebug", ">= 3.5"
  spec.add_development_dependency "standardrb"
  spec.add_development_dependency "timecop"
end
