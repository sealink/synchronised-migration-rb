# Synchronised Migration

## 3.2.0

- [PLAT-1175] Update to Ruby 3.2

## 3.1.0

- [PLAT-183] Ruby 3.1 and publish coverage with github action

## 3.0.0

- [OPS-201] Migrate library to CLI tool

## 2.2.0

- [TT-8617] Update to build with github actions / ruby 3.0

## 2.1.2

- [TT-7511] Use the correct `ex` option for key value expiry times instead of `ttl`

## 2.1.1

- [TT-5896] Early exit from migration inside lock if already completed

## 2.1.0

- [TT-5827] Add "success key" when REDLOCK_VERSION_SUFFIX is set, preventing repeat runs
- [TT-5830] Add rake and Rakefile for 'rake release'

## 2.0.0

- [DO-168] Removed requirement for defining RedisConfig, now set on
  SynchronisedMigration module

## 1.0.2

- [DO-105] Use the `original` environment instead

## 1.0.1

- [DO-100] Address the Travis issue

## 1.0.0

- [DO-100] Allow nesting bundler exec

## 0.1.0

- [DO-70] Use Redis to synchronise migrations across multiple deployments
