# Synchronised Migration

[![Gem Version](https://badge.fury.io/rb/synchronised_migration.svg)](http://badge.fury.io/rb/synchronised_migration)
[![Build Status](https://github.com/sealink/synchronised-migration-rb/workflows/Build%20and%20Test/badge.svg?branch=master)](https://github.com/sealink/synchronised-migration-rb/actions)

This gem makes it possible to deploy multiple instances with data migration
simultaneously.  It uses Redis to ensure that there will be only one migration
running.

This gem works out of the box with a Rails project.  It should work with other
Ruby projects so long as you load the rake task in Rakefile instead of relying
on Railtie.

This is a Ruby port of the same logic written in PHP in our [Craft
Docker](https://github.com/sealink/craft-docker) project.

## Usage

Module `SynchronisedMigration` needs to be configured as below.

```ruby
  SynchronisedMigration.configure do |config|
    config.host = 'example.com'
    config.port = 6379
    config.db = 0
  end
```

Configuration can be called by using
```SynchronisedMigration.redis_config.host``` or similar.

You may override these settings through environment variables.

```
SYNCHRONISED_COMMAND=bin/launch/migrate
WITH_CLEAN_BUNDLER_ENV=1 # Non-empty for true
REDLOCK_TIMEOUT_MS=3600000
REDLOCK_RETRY_DELAY_MS=200
REDLOCK_LOCK_KEY=migration-in-progress
REDLOCK_FAIL_KEY=migration-failed
```

Run this before you launch the application during deployment.

```
$ rake synchronised_migrate:execute
```

## Release

To publish a new version of this gem the following steps must be taken.

* Update the version in the following files
  ```
    CHANGELOG.md
    lib/synchronised_migration/version.rb
  ````
* Create a tag using the format v0.1.0
* Follow build progress in GitHub actions
