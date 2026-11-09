# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Each entry cites the issue that drove it, so that the release checkpoint can
find the work behind a tag.

## [Unreleased]

### Added

- Commit zero: the Laravel 13 skeleton on PHP 8.5 and FrankenPHP, the Docker
  stack, the `Makefile` front door, the provenance check and its hook, and the
  documentation set. ([#8](https://github.com/marcth-labs/proving-ground/issues/8))
- The `licence` gate: `bin/check-licences` and `make licence`, refusing any
  production dependency that declares no licence on the `MIT` / `BSD-3-Clause`
  / `Apache-2.0` allowlist, and failing on drift between the committed
  `THIRD-PARTY-LICENCES.md` inventory and `composer.lock`.
  ([#31](https://github.com/marcth-labs/proving-ground/issues/31))

### Changed

- Relicensed from MIT to `GPL-3.0-or-later`. See
  [ADR 3](docs/adr/0003-outbound-licence-and-the-dependency-allowlist.md).
  ([#28](https://github.com/marcth-labs/proving-ground/issues/28))
