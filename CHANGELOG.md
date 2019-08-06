# Synchronised Migration

## Unreleased

* [TT-5827] Add "success key" when REDLOCK_VERSION_SUFFIX is set, preventing repeat runs
* [TT-5830] Add rake and Rakefile for 'rake release'

## 2.0.0

* [DO-168] Removed requirement for defining RedisConfig, now set on
  SynchronisedMigration module

## 1.0.2

* [DO-105] Use the `original` environment instead

## 1.0.1

* [DO-100] Address the Travis issue

## 1.0.0

* [DO-100] Allow nesting bundler exec

## 0.1.0

* [DO-70] Use Redis to synchronise migrations across multiple deployments
