# Third-party licences

**Generated. Do not edit.** Produced by
[`bin/check-licences`](bin/check-licences) from
`composer licenses --locked --no-dev`, and drift-checked by `make licence`:
if this file and `composer.lock` disagree, the gate fails. Regenerate it
with `make licence-write`.

**This is an inventory, not a NOTICE,** and the distinction is not
pedantry. `composer licenses` reports a package's name, version and
declared licences and nothing else — no copyright holders, no licence
texts, no URLs — so this file cannot discharge an attribution obligation
and does not claim to. None is triggered: `vendor/` is untracked and
nothing here publishes an image, so what this repository conveys is a
lockfile *naming* these libraries rather than the libraries themselves.
The full-text version becomes correct the day something is actually
redistributed.

**Production dependencies only** (`--no-dev`), because dev tooling is never
combined into the conveyed work. The reasoning, and the outbound licence
these are checked against, are in
[ADR 3](docs/adr/0003-outbound-licence-and-the-dependency-allowlist.md).

## Allowlist

`MIT`, `BSD-3-Clause`, `Apache-2.0`

A package passes on **any one** declared licence matching — Composer's
documented disjunctive form — which is why the *Accepted under* column
exists, and why the GPL strings below are visible rather than quietly
filtered out. Nothing here is GPL-encumbered: `nette/utils` and
`nette/schema` offer a choice, and this tree takes BSD-3-Clause.

## Dependencies

| Package | Version | Declared | Accepted under |
|---|---|---|---|
| `brick/math` | 1.0.0 | MIT | MIT |
| `carbonphp/carbon-doctrine-types` | 3.2.1 | MIT | MIT |
| `dflydev/dot-access-data` | v3.0.3 | MIT | MIT |
| `doctrine/inflector` | 2.1.0 | MIT | MIT |
| `doctrine/lexer` | 3.0.3 | MIT | MIT |
| `dragonmantank/cron-expression` | v3.6.1 | MIT | MIT |
| `egulias/email-validator` | 4.0.4 | MIT | MIT |
| `fruitcake/php-cors` | v1.4.0 | MIT | MIT |
| `graham-campbell/result-type` | v1.2.0 | MIT | MIT |
| `guzzlehttp/guzzle` | 8.3.0 | MIT | MIT |
| `guzzlehttp/promises` | 3.1.0 | MIT | MIT |
| `guzzlehttp/psr7` | 3.2.0 | MIT | MIT |
| `guzzlehttp/uri-template` | v2.0.1 | MIT | MIT |
| `laravel/framework` | v13.38.0 | MIT | MIT |
| `laravel/prompts` | v0.3.26 | MIT | MIT |
| `laravel/serializable-closure` | v2.1.0 | MIT | MIT |
| `laravel/tinker` | v3.0.2 | MIT | MIT |
| `league/commonmark` | 2.10.4 | BSD-3-Clause | BSD-3-Clause |
| `league/config` | v1.2.0 | BSD-3-Clause | BSD-3-Clause |
| `league/flysystem` | 3.36.0 | MIT | MIT |
| `league/flysystem-local` | 3.35.3 | MIT | MIT |
| `league/mime-type-detection` | 1.17.0 | MIT | MIT |
| `league/uri` | 7.9.0 | MIT | MIT |
| `league/uri-interfaces` | 7.9.0 | MIT | MIT |
| `monolog/monolog` | 3.12.1 | MIT | MIT |
| `nesbot/carbon` | 3.15.0 | MIT | MIT |
| `nette/schema` | v1.4.0 | BSD-3-Clause, GPL-2.0-only, GPL-3.0-only | BSD-3-Clause |
| `nette/utils` | v4.1.6 | BSD-3-Clause, GPL-2.0-only, GPL-3.0-only | BSD-3-Clause |
| `nikic/php-parser` | v5.9.0 | BSD-3-Clause | BSD-3-Clause |
| `nunomaduro/termwind` | v2.4.0 | MIT | MIT |
| `phpoption/phpoption` | 1.10.0 | Apache-2.0 | Apache-2.0 |
| `psr/clock` | 1.0.0 | MIT | MIT |
| `psr/container` | 2.0.2 | MIT | MIT |
| `psr/event-dispatcher` | 1.0.0 | MIT | MIT |
| `psr/http-client` | 1.0.3 | MIT | MIT |
| `psr/http-factory` | 1.1.0 | MIT | MIT |
| `psr/http-message` | 2.0 | MIT | MIT |
| `psr/log` | 3.0.2 | MIT | MIT |
| `psr/simple-cache` | 3.0.0 | MIT | MIT |
| `psy/psysh` | v0.12.24 | MIT | MIT |
| `ramsey/collection` | 2.1.1 | MIT | MIT |
| `ramsey/uuid` | 4.9.4 | MIT | MIT |
| `symfony/clock` | v8.1.9 | MIT | MIT |
| `symfony/console` | v8.1.9 | MIT | MIT |
| `symfony/css-selector` | v8.1.6 | MIT | MIT |
| `symfony/deprecation-contracts` | v3.7.1 | MIT | MIT |
| `symfony/error-handler` | v8.1.8 | MIT | MIT |
| `symfony/event-dispatcher` | v8.1.5 | MIT | MIT |
| `symfony/event-dispatcher-contracts` | v3.7.1 | MIT | MIT |
| `symfony/finder` | v8.1.8 | MIT | MIT |
| `symfony/http-foundation` | v8.1.9 | MIT | MIT |
| `symfony/http-kernel` | v8.1.9 | MIT | MIT |
| `symfony/mailer` | v8.1.7 | MIT | MIT |
| `symfony/mime` | v8.1.7 | MIT | MIT |
| `symfony/polyfill-ctype` | v1.37.0 | MIT | MIT |
| `symfony/polyfill-intl-grapheme` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-intl-idn` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-intl-normalizer` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-mbstring` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-php80` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-php82` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-php84` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-php85` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-php86` | v1.43.0 | MIT | MIT |
| `symfony/polyfill-time` | v1.42.0 | MIT | MIT |
| `symfony/polyfill-uuid` | v1.43.0 | MIT | MIT |
| `symfony/process` | v8.1.9 | MIT | MIT |
| `symfony/routing` | v8.1.9 | MIT | MIT |
| `symfony/service-contracts` | v3.7.3 | MIT | MIT |
| `symfony/string` | v8.1.9 | MIT | MIT |
| `symfony/translation` | v8.1.5 | MIT | MIT |
| `symfony/translation-contracts` | v3.7.1 | MIT | MIT |
| `symfony/uid` | v8.1.9 | MIT | MIT |
| `symfony/var-dumper` | v8.1.9 | MIT | MIT |
| `tijsverkoyen/css-to-inline-styles` | v2.4.0 | BSD-3-Clause | BSD-3-Clause |
| `vlucas/phpdotenv` | v5.7.0 | BSD-3-Clause | BSD-3-Clause |
| `voku/portable-ascii` | 2.1.1 | MIT | MIT |
