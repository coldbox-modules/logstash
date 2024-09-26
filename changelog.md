# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [Unreleased]

### Added

* Added config option for detached appenders ( [introduced in `cbelasticsearch` `v3.4.0`](https://cbelasticsearch.ortusbooks.com/logging#detached-appenders) )
* Added interceptor and custom interception to log to specific appenders ( e.g. detached )

### Changed

* Remove JSONToRC module dependency as Coldbox handles this by default
* Bumped `cbelasticsearch` dependency to `v3.4.0`

## [3.0.4] => 2023-11-19

### Changed

* Bump cbElasticsearch version to 3.2

## [3.0.3] => 2023-06-01

### Changed

* Bump cbElasticsearch version to 3.1

## [3.0.2] => 2023-03-28

### Changed

* Bump cbElasticsearch version to 3.0.2

## [3.0.1] => 2023-03-12

### Changed

* Bump cbElasticsearch version to 3.0.1

## [3.0.0] => 2023-03-03

### Changed

* Updates `cbElasticsearch` dependency for v3
* Module settings and environment variable changes to support v3 of Logstash appender

## [2.0.1] => 2023-01-30

### Fixed

* Revert to old log index pattern until data stream support can be implemented

## [2.0.0] => 2023-01-29

### Changed

* Bump cbElasticsearch version minimum to 2.4.0
* Bump Coldbox to v6
* Changes default log index pattern to `logs-` to reflect v8 changes in Kibana/Logstash defaults

## [1.2.1] => 2022-09-21

### Added

* Added support for `LOGSTASH_APPLICATION_NAME` environment variable

### Changed

* Changed build process to use Github Actions
* Migrated README content to GitBook

## [1.2.0] => 2022-08-12

### Fixed

* Ensured SSL protocol on download location of package

## [1.1.1] => 2020-12-10

### Fixed

* Remove build artifact from final package

## [1.1.0] => 2020-11-03

### Added

* Added additional settings for number of index shards and replicas

### Changed

* Modifies appender preflight to use base appender preflight
* Modifies default logstash index prefix to use Kibana/ES conventions
* Bumps `cbElasticsearch` dependency to `v2.1.0`

## [1.0.0] => 2020-09-11

### Added

* Initial release of module
