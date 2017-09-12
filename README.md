# Synchronised Migration

[![Build Status](https://travis-ci.org/sealink/synchronised-migration-rb.svg?branch=master)](https://travis-ci.org/sealink/synchronised-migration-rb)

This gem makes it possible to deploy multiple instances with data migration
simultaneously.  It uses Redis to ensure that there will be only one migration
running.

This gem works out of the box with a Rails project.  It should work with other
Ruby projects so long as you load the rake task in Rakefile instead of relying
on Railtie.

This is a Ruby port of the same logic written in PHP in our [Craft
Docker](https://github.com/sealink/craft-docker) project.

## Usage

Class `RedisConfig` needs to be provided as follow.

```
RedisConfig.get[:host] # example.com
RedisConfig.get[:port] # 6379
RedisConfig.get[:db] # 0
```

You may override these settings through environment variables.

```
SYNCHRONISED_COMMAND=bin/launch/migrate
REDLOCK_TIMEOUT_MS=3600000
REDLOCK_RETRY_DELAY_MS=200
REDLOCK_LOCK_KEY=migration-in-progress
REDLOCK_FAIL_KEY=migration-failed
```

Run this before you launch the application during deployment.

```
$ rake synchronised_migrate:execute
```

## Testing

Please refer to `.travis.yml` for testing.
