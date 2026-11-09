# Context

A glossary, and nothing else. Terms used in this repository that do not mean
what a reader would otherwise assume, or that name something specific enough to
be worth pinning down. Reasoning lives in [`docs/adr/`](docs/adr/); the process
narrative lives in [`docs/way-of-working.md`](docs/way-of-working.md).

The delivery pipeline comes first and the application second, because in this
repository the pipeline is the product and the application is the substrate it
operates on.

---

## The delivery pipeline

**Implementer** — a credential permitted to author non-merge commits and open
pull requests, and forbidden to approve or merge. Not a person and not
necessarily an agent. See
[ADR 1](docs/adr/0001-implementer-and-approver-credentials.md).

**Approver** — a credential permitted to approve and merge, and forbidden to
author non-merge commits. The approver must differ from the author of the
change being merged.

**Attribution** — what produced a change, recorded by the `Generated-By:`
trailer. Distinct from authorization.

**Authorization** — which credential performed an act and what that credential
was permitted to do, recorded by the commit author field and enforced by the
branch protection in [`.github/protection/`](.github/protection/).

**Gate** — a check that blocks. It is in the required-check list, it fails
closed, and its definition lives in this repository.

**Platform gate** — a check that blocks, but whose definition lives with the
vendor rather than in this repository.

**Aid** — something that informs and never blocks. Must be labelled as an aid
wherever it appears, because an aid presented as a gate is decoration.

**The gate** (definite article) — the full ordered set of required status
checks a change must pass. It grows across iterations; the authoritative list
is the `Makefile` and the composer scripts CI invokes, not the table in
`docs/way-of-working.md`.

**Allowlist** — the set of **inbound** dependency licences whose terms permit
this repository's own work to be offered under its outbound licence. Three
entries, measured-present rather than anticipatory. A refusal is a ticket, not
a repair: widening the list to turn a red green is how a genuinely GPL-only
package gets in. See
[ADR 3](docs/adr/0003-outbound-licence-and-the-dependency-allowlist.md).

**Third-party inventory** — `THIRD-PARTY-LICENCES.md`, generated from the
lockfile and drift-checked. An *inventory*, not a NOTICE: `composer licenses`
carries no copyright holders and no licence texts, so it cannot discharge an
attribution obligation. None is triggered — `vendor/` is untracked and nothing
here publishes an image, so what this repository conveys is a lockfile naming
these libraries rather than the libraries themselves.

**Commit zero** — the first commit carrying any content. Not the root commit:
the root commit is empty by construction.

**Root commit** — the one commit in this repository that no pull request
reviewed, because no pull request can target a branch that does not exist. Its
tree is git's canonical empty tree,
`4b825dc642cb6eb9a060e54bf8d69288fbee4904`, so an assessor confirms it
introduced nothing by comparing one well-known constant.

**Record pull request** — a pull request whose content is the record of a
decision rather than a change to the application. A decision is finished when
its record lands on `main` through an approved pull request, not when its
tracking issue is closed.

**Ratified** — of a decision: its record has landed on `main` through an
approved pull request. A GitHub issue is editable, deletable by an admin,
unsigned, and resolved by one person; it is a working surface, never an audit
record.

**Map** — a wayfinder issue holding the decisions an effort has made and
pointing at the tickets that hold their detail. Decision tickets are not board
items; the pull request that ratifies a decision is.

**Iteration** — a fixed two-day box with a theme. Scope is the variable; dates
are not. A started iteration never has its dates or title changed.

**Fresh-context verification** — verification of an iteration's claims by an
agent with no memory of the implementation, cloning the tag cold. Replaces a
second reviewing agent, which would be correlated rather than independent.

**Red-before-green** — the discipline of pushing the failing specification
commit *alone*, waiting for CI to record it red, and only then pushing the
implementation. Actions attaches check runs to a push's tip, so a combined push
leaves the red commit unverifiable.

**Specification** — the executable acceptance suite under `tests/Acceptance/`.
A `.feature` file cannot contain PHP, which is what makes "what, never how" a
mechanical property rather than a review convention.

**Surviving mutant** — a hole in the specification, not a weak test. It means a
behavioural change exists that the specification permits, so the fix is a
scenario, not an assertion bolted onto the mutated line.

---

## The application

The application is a health-reporting HTTP API. It exists to give the pipeline
something real to operate on, and is deliberately small.

**Liveness** — `GET /up`. Returns 200 if the framework booted without
exceptions. Framework-provided, and what the container healthcheck polls.

**Readiness** — the service's own report of whether it can do its job, which
means whether its datastore and its cache are reachable. Arrives in iteration 3
with its first acceptance scenario. Distinct from liveness: a live service that
cannot reach its database is not ready.

**Observed dependency** — a dependency whose reachability readiness reports on.
Currently MariaDB and Redis. The term matters because it is what stops the
cache being decoration: Redis is exercised by the specification rather than
merely present.
