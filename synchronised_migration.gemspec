lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'synchronised_migration/version'

Gem::Specification.new do |spec|
  spec.name          = 'synchronised_migration'
  spec.version       = SynchronisedMigration::VERSION
  spec.authors       = ['Alvin Yim', 'Stefan Cooper']
  spec.email         = 'support@travellink.com.au'
  spec.description   = 'Use Redis to record the data migration status'
  spec.summary       = 'For deploying to multiple instances simultaneously'
  spec.homepage      = 'https://github.com/sealink/synchronised-migration-rb'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'redlock', '>= 0.2'
  spec.add_dependency 'redis'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'simplecov-rcov', '>= 0.2'
  spec.add_development_dependency 'rspec', '>= 3.6'
  spec.add_development_dependency 'pry-byebug', '>= 3.5'
end
