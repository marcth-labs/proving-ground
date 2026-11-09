# 3. The outbound licence, and the dependency allowlist that follows from it

- **Status:** Accepted
- **Decided:** 2026-10-31
- **Ratified:** on the merge of [#34](https://github.com/marcth-labs/proving-ground/pull/34)
- **Tickets:** [#28](https://github.com/marcth-labs/proving-ground/issues/28), [#31](https://github.com/marcth-labs/proving-ground/issues/31)

## Context

The ticket behind this record asked what a dependency-licence allowlist should
contain. That question cannot be answered on its own terms. An allowlist is the
set of **inbound** licences whose terms permit the combined work to be offered
under the repository's **own** licence, so the outbound licence is upstream of
it — and the outbound licence had never been decided.

It was always this repository's to choose. **`laravel/laravel` deliberately
ships no `LICENSE` file** — a project created from the skeleton is its author's
own work to licence, which is why there was nothing to inherit and nothing to
edit. Commit zero exercised that choice by writing an MIT `LICENSE` from
scratch (`9e4880b`), and recorded no reason for it.

The session that found this opened by justifying the gate as *homage*: a
rendering of a control with no live obligation, since there is no deployed
environment. **That framing was wrong and is retired.** This repository is
public and is itself the conveyed artifact. What it does *not* convey is
third-party **library** code — `vendor/` is untracked, only `composer.lock` is
committed, and nothing here publishes an image.

The skeleton is not a counter-example, though a reader checking this will find
files in it byte-identical to `laravel/laravel` — `artisan`,
`public/index.php`, an `AppServiceProvider` whose two methods are empty. A
Laravel application *is* a template that composes its libraries and applies its
own customisations on top; the template is given away without a licence file
for exactly that reason, and a file still being identical means only that it
has not needed changing yet.

So the thing conveyed is *a lockfile naming third-party code*, and the
allowlist's function is real: it decides what a future `composer require` is
allowed to bind this repository to.

One premise inherited from the ticket is corrected rather than carried.
**A third-party inventory's force does not come from our outbound licence.** It
discharges *their* terms — MIT's copyright-notice clause, BSD-3-Clause clause
2, Apache-2.0 §4(d) — which bind a downstream redistributor whatever we license
our own code under. What GPLv3 demands of someone who conveys a derivative is
its complete corresponding source under the same terms, and that is a different
obligation on a different party.

### The tree, measured rather than recalled

Run in the composed stack against the committed lock, before any dependency was
added:

| | production (`--no-dev`) | with dev |
|---|---|---|
| packages | 77 | 110 |
| MIT | 69 | 78 |
| BSD-3-Clause | 7 | 31 |
| Apache-2.0 | 1 (`phpoption/phpoption`) | 1 |
| GPL-2.0-only | 2 | 2 |
| GPL-3.0-only | 2 | 2 |

**There is GPL in the production tree of a stock Laravel 13 install.**
`nette/utils` and `nette/schema` each declare
`["BSD-3-Clause","GPL-2.0-only","GPL-3.0-only"]`, reached by
`laravel/framework` → `league/commonmark` → `league/config`. Nothing is
GPL-encumbered: that array is Composer's **disjunctive** form, and
`vendor/nette/utils/license.md` confirms the author's intent — *"you may use
Nette Framework under the terms of either the New BSD License or the GNU
General Public License (GPL)"*.

This is not a footnote. It is the fact that decides how the check is written,
and it is below in full.

## Decision

**The repository relicences from MIT to `GPL-3.0-or-later`, and one gate —
`licence` — makes two assertions from a single
`composer licenses --locked --no-dev --format=json` pass: every production
dependency declares at least one licence on a three-entry allowlist, and the
committed `THIRD-PARTY-LICENCES.md` is what that pass produces.**

### `GPL-3.0-or-later`

Nothing in the tree is violated by it. MIT, BSD-3-Clause and Apache-2.0 are
each one-way compatible **into** GPLv3; the only incompatibility present is
`GPL-2.0-only`, and nette offers BSD-3-Clause as an alternative, so it never
binds. GPLv**3** specifically, because `phpoption/phpoption` is Apache-2.0,
which is GPLv3-compatible and GPLv2-**in**compatible.

`-or-later` rather than `-only`, per the FSF's own recommendation: `-only`
freezes the repository against a future version of the licence for no benefit
here. **No per-file licence headers.** §5(a)'s modification notices bind
modifiers rather than original authors, and a header on every file is noise in
a repository whose subject is what a reader can check.

Three tracked files asserted MIT and change: `LICENSE`, `composer.json` and
`README.md`. The MIT mentions in `docs/research/` describe dependencies and
stay.

### The allowlist: `MIT`, `BSD-3-Clause`, `Apache-2.0`

Measured-present, and a conservative subset of the GPLv3-compatible set. An
anticipatory list — `BSD-2-Clause`, `ISC`, `Unlicense`, `CC0-1.0` — was
rejected: a list naming licences no package uses is a list nobody chose. Every
future addition arrives as a refusal, a ticket and a pull request, which is the
friction `AGENTS.md` already requires for dependencies, arriving one step
earlier with a machine behind it instead of a convention.

### Any one declared licence matching is a pass

Composer's documentation (`doc/04-schema.md`, §`license`), verbatim:

> For a package, when there is a choice between licenses ("disjunctive
> license"), multiple can be specified as an array.

So the rule is **any one match**, and the gate **prints the licence it accepted
each package under** — `nette/utils: accepted under BSD-3-Clause`. The
*Accepted under* column in the inventory is the same fact made permanent, which
is why the GPL strings stay visible in the artifact instead of ambushing the
next reader.

Two findings came out of fetching that citation, neither of which was being
looked for, and both of which argue for printing rather than passing silently:

- **Composer's machine-readable schema does not encode this.**
  `res/composer-schema.json`, extracted from the installed phar, defines
  `license` as
  `{"type": ["string","array"], "description": "License name. Or an array of license names."}`
  and says nothing about disjunction. The semantics live in prose only, and no
  tooling expresses or enforces them.
- **A parenthesised expression is a legal declaration in both directions.** The
  same documentation permits `"(LGPL-2.1-only or GPL-3.0-or-later)"` for
  disjunctive and, *"when multiple licenses need to be applied ("conjunctive
  license"), they should be separated with "and" and enclosed in
  parentheses."*

### The two traps, recorded because a green is available at both

**A check written the obvious way refuses stock Laravel 13 on its first run.**
*Every* declared licence must be allowlisted is the natural rule, and nette
fails it. The natural repair is to add `GPL-3.0-only` to the allowlist, which
then silently permits a genuinely GPL-only package. That is the `PAO_DISABLE`
shape exactly: a wrong green reached by repairing a wrong red.

**A parenthesised expression arrives as a single array element that is not a
bare SPDX identifier, so it is refused — and it stays refused.** Teaching the
gate to parse expressions means writing a disjunctive parser, and a disjunctive
parser applied to a conjunctive expression accepts a package on a licence it
only half carries. A refusal costs one ticket. That costs the claim.

### An inventory, not a NOTICE

The alternative offered during the decision was a NOTICE file *instead of* a
gate. The attribution obligation a NOTICE discharges is triggered by
redistributing the covered code, and this repository redistributes none of it,
so a NOTICE here is voluntary.

**And "just a NOTICE" is the more expensive option, not the cheaper one.**
`composer licenses --locked --format=json` returns name, version and licence
array and nothing else — no copyright holders, no licence texts, no URLs,
verified against the actual payload. A compliant NOTICE needs per-package text,
which lives in `vendor/` under inconsistent filenames (`nette/utils/license.md`
against `league/commonmark/LICENSE`), so it needs an installed tree and fuzzy
filename matching: strictly more machinery for an obligation nobody is under.

The instinct behind the question is right and is adopted — **an artifact beats
a rule**, which is this repository's position everywhere else. So one generator
emits a committed [`THIRD-PARTY-LICENCES.md`](../../THIRD-PARTY-LICENCES.md),
drift-checked exactly as the OpenAPI document will be, labelled an inventory
rather than a NOTICE in its own header, with the full-text version named as the
thing that becomes correct the day something is actually redistributed.

Both assertions sit in one gate because they answer one question — *is the
licence position of this tree what the repository says it is?* The division of
labour is this repository's own taxonomy: **an inventory diff somebody has to
read and notice GPL in is an aid; the allowlist is what makes it a gate.**

### Composer's built-in command, no plugin

`composer licenses` is part of Composer and carries `--format=json`, `--no-dev`
and `--locked`. The third-party checkers (`dominikb/composer-license-checker`,
`madewithlove/license-checker`) are Composer **plugins**, which means an
`allow-plugins` entry — the exact class of configuration whose silent absence
[#26](https://github.com/marcth-labs/proving-ground/issues/26) measured, and a
conspicuous thing to put in front of an assessor when the gate's whole subject
is dependency hygiene.

**`--locked` is load-bearing.** Reading the committed lock rather than the
installed tree means a transitive licence change can only reach `main` through
a lock change — that is, through a pull request — so the gate catches it at the
moment it is proposed. It also makes the check runnable with nothing installed.

**`--no-dev` is a decision, not an omission.** Dev tooling is never combined
into the conveyed work, so the compatibility question does not reach it. This
reverses a first recommendation of one list over both trees, which rested on
the discarded homage framing; under inbound/outbound compatibility the premise
simply is not there. The measured cost of excluding dev is nil — the dev tree
adds 24 further BSD-3-Clause packages and no licence that is not already on the
list.

## Consequences

**Good.**

- The question *"what may this repository depend on?"* has a machine-checked
  answer rather than a convention, and the answer is visible in a committed
  file rather than only in a check run.
- The GPL already in the tree is stated in the artifact instead of discovered
  by the next person to run a licence tool.
- `--locked` puts the check at the moment of proposal. A transitive licence
  change cannot arrive quietly between pull requests.

**Costs, accepted.**

- **GPLv3 does nothing for a service.** Copyleft triggers on conveying, and
  running a server is not conveying. A forker who deploys this API and ships
  nothing owes nothing. **AGPLv3 was offered and declined** — it matches the
  motive more closely but is banned outright by a visible number of
  organisations, which would make a reader's first reaction to this repository
  a licensing-policy question rather than a pipeline question.
- **The likeliest appropriation is unreachable by either licence.** Lifting
  this pipeline into a private company repository is neither conveying (GPLv3)
  nor network interaction with users (AGPLv3 §13). This decision does less work
  than it appears to.
- **The allowlist will refuse something legitimate.** It is measured-only, so
  the first `BSD-2-Clause` or `ISC` package stops a build. That is the design
  working, not a defect, and the cost is one ticket each time.
- **There is no CI job yet.** `.github/workflows/` does not exist. Per
  `AGENTS.md` — CI may only invoke artifacts, never implement — the artifact is
  separable from the job, so this ships as `make licence`, runnable on a laptop
  today, and the job wires in when the workflow lands. Until then the gate is a
  gate only by intent.

## Alternatives rejected

**A NOTICE file instead of a gate.** Rejected above: voluntary here, and
strictly more machinery than the thing it would replace.

**One allowlist over both the production and dev trees.** Rejected once the
homage framing went: the dev tree is not combined into the conveyed work, so
there is no compatibility question to answer about it. Recorded by name so that
a future session widening the scope knows it is reversing something rather than
filling a gap.

**A compatibility matrix in the gate.** Raised as an objection to relicensing —
*"GPL makes the check need one"* — and **withdrawn as wrong**. An allowlist may
be a conservative subset of what the outbound licence permits. `MIT`,
`BSD-3-Clause`, `Apache-2.0` is a safe subset under GPLv3 exactly as under MIT,
so the gate is the same flat list either way. Only this record's derivation
changes.

**A third-party licence-checker plugin.** Rejected above: it buys an
`allow-plugins` entry in exchange for features this gate does not use.

## Limits, and what was not verified

- **The inventory is not a compliance NOTICE** and says so in its own header.
- **The licence facts for packages not yet installed are unmeasured.** The
  Behat and PHP_CodeSniffer trees in particular have never been resolved, and
  either could turn up `BSD-2-Clause` or `ISC` and stop a gate build dead. The
  first session to hit that should not mistake it for a defect.
- **GPLv3's effect here is narrow**, as recorded under *Costs* above, and
  nothing in this repository should be read as claiming otherwise.
