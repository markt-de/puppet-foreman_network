# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [v1.3.0] - 2023-12-04

### Added
* Add resolver options

## [v1.2.0] - 2023-08-21

### Added
* Enable GitHub Actions

### Changed
* Update OS support, dependencies and Puppet version
* Update PDK to 3.0.0

### Fixed
* Fix typo in parameter name `$manage_network_interface_restart`
* Fix compatibility with puppetlabs/stdlib v9.0.0
* Fix unit tests
* Partially fix acceptance tests on Rocky 8

## [v1.1.0] - 2022-08-17

### Fixed
* Fix network restart on EL8 ([#1])

## [v1.0.0] - 2020-02-27

Initial release

[Unreleased]: https://github.com/markt-de/puppet-foreman_network/compare/v1.3.0...HEAD
[v1.3.0]: https://github.com/markt-de/puppet-foreman_network/compare/v1.2.0...v1.3.0
[v1.2.0]: https://github.com/markt-de/puppet-foreman_network/compare/v1.1.0...v1.2.0
[v1.1.0]: https://github.com/markt-de/puppet-foreman_network/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/markt-de/puppet-foreman_network/tree/v1.0.0
[#1]: https://github.com/markt-de/puppet-foreman_network/pull/1
