# Synchronised Migration

[![Gem Version](https://badge.fury.io/rb/synchronised_migration.svg)](http://badge.fury.io/rb/synchronised_migration)
[![Build Status](https://github.com/sealink/synchronised-migration-rb/workflows/Build%20and%20Test/badge.svg?branch=master)](https://github.com/sealink/synchronised-migration-rb/actions)

This gem makes it possible to deploy multiple instances with data migration
simultaneously. It uses Redis to ensure that there will be only one migration
running.

## Usage

### Migrating an application

```
bundle exec synchronised-migration migrate --config=migration.yml --version=1.2.3
```

### Checking lock stats

```
bundle exec synchronised-migration status --config=migration.yml --version=1.2.3
```

### Clearing locks

If a previous migration has failed a new one will not be allowed to start
unless it is first cleared.

```
bundle exec synchronised-migration clear --config=migration.yml
```

If you wish to clear all locks, \*including the running lock then you must also provide version

```
bundle exec synchronised-migration clear --config=migration.yml --version=1.2.3 --all
```

### Configuration

| Key                      | Description                             |
| ------------------------ | --------------------------------------- |
| redis_uri                | Redis server to use for locking         |
| application              | Application being migrated              |
| version                  | Version being migrated too              |
| debug                    | Enable additional debug information     |
| command                  | Command to execute for the migration    |
| timeout_milliseconds     | Timeout to wait for the lock            |
| retry_delay_milliseconds | Retry for the lock every x milliseconds |

### Overriding config file options

You may override certain config options such as the `redis-uri` and the ```debug``` flag
by providing them via cli options.

```
bundle exec synchronised-migration migrate --config=migration.yml --version=1.2.3 --redis_uri=redis://127.0.0.1:6379/0
```

## Release

To publish a new version of this gem the following steps must be taken.

- Update the version in the following files
  ```
    CHANGELOG.md
    lib/synchronised_migration/version.rb
  ```
- Create a tag using the format v0.1.0
- Follow build progress in GitHub actions
