# Way of working

How a change gets from an idea to `main` in this repository, and what is
enforced at each step. Reasoning for the hard decisions lives in
[`docs/adr/`](adr/); terms are defined in [`CONTEXT.md`](../CONTEXT.md); the
imperative form for agents is [`AGENTS.md`](../AGENTS.md).

## The arrangement

Two credentials. The **implementer** writes code, commits, and opens pull
requests. The **approver** reviews and merges. The implementer is not a
repository administrator, so it cannot land its own work even once that work is
approved. See
[ADR 1](adr/0001-implementer-and-approver-credentials.md).

**Both credentials are held by one person.** This repository demonstrates an
enforcement mechanism. It does not claim compliance with SOC 2 or any other
framework, and an arrangement where one individual holds both roles would not
satisfy one. What is on display is that the control is real: the approval is
required by the platform, the approver's act lands in the artifact as a merge
commit, and the implementer is structurally unable to bypass either.

## The loop

1. An issue describes one mergeable change. It carries a `Decision:` line
   citing the ADR and the map ticket behind it, or `Decision: none` written
   out.
2. The implementer branches: `<type>/<issue>-<slug>`.
3. The implementer commits, signed, under the implementer credential, with a
   Conventional Commits subject, `Refs: #NN` and a `Generated-By:` trailer.
4. The implementer opens a pull request from the template. The body is the
   audit record.
5. CI runs the gate.
6. The approver reviews and merges. Merge commits only.

**This loop is under revision.** It is being replaced by a two-approval shape —
the specification approved as its own artifact before any implementation
exists, then the implementation approved separately, then promotion to `main`
from an integration branch. What is written above is what is enforced today.
See [the delivery loop and the integration branch](https://github.com/marcth-labs/proving-ground/issues/21).

### Red before green

A change that adds behaviour pushes its failing specification commit **alone**,
waits for CI to record it red, and only then pushes the implementation.

This is the repository's most distinctive discipline, and it is only provable
because of a detail of how Actions works: check runs attach to the tip of a
push, so a combined push leaves the red commit with no recorded conclusion. The
pull request body names the red SHA and the green SHA, and from iteration 2 CI
checks that the named red commit is an ancestor of the head *and* that its
recorded conclusion was `failure` — which turns the discipline from a
convention into a gate.

## Naming

| Thing | Convention | Why |
|---|---|---|
| Issue title | Plain imperative | It is a task, not a commit |
| Pull request title | Conventional Commits, ≤72 characters | It **becomes the merge commit subject** on `main`, so this and the commit-subject convention are one convention rather than two |
| Branch | `<type>/<issue>-<slug>` | Ergonomics only — with `delete_branch_on_merge` on, a branch name never enters permanent history |
| Commit subject | Conventional Commits, ≤72 characters after the type | Enforced by `bin/check-provenance` |
| Tag | `v<major>.<minor>.<patch>`, one per iteration | Annotated and signed |

GitHub appends `(#N)` to the merge subject, and that `#N` is the **pull
request** number, not the issue — which is why `Refs: #NN` is still required in
the body.

## What lands on `main`

**Merge commits only.** Squash and rebase are disabled at the repository level,
and the reason is a fact rather than a preference: GitHub performs both
server-side with no access to the implementer's private key, so it re-signs
with its own `web-flow` key. Under squash merging, `main` would contain zero
implementer-signed commits while "require signed commits" stayed green — a
control reporting healthy over a hollowed-out claim.

The noise objection dissolves. `git log --first-parent main` gives exactly what
squash would have: one entry per approved pull request. The full log keeps the
trail. And a history where every change landed perfectly first time is
indistinguishable from a manufactured one — here, the fumbles are the proof of
work.

The pull request body becomes the merge commit body, so the record is permanent
and uneditable. This is deliberate: an issue comment or a pull request
description can be edited afterwards by one person, and a merge commit cannot.

## The gate

Documentation. **The authoritative list is the `Makefile` and the composer
scripts CI invokes** — prose describing commands that no longer exist is the
drift failure mode here.

One workflow, one job per gate, and the job name, the `make` target and the
composer script share a name. Everything executes in the composed stack, which
buys a dividend: CI continuously proves that `docker compose up -d` works from
a clean clone, on every pull request.

| Gate | Arrives | What it blocks on |
|---|---|---|
| `build` | 2 | The `ci` and `prod` images compile. Built once and shipped as an artifact, so every later gate provably ran against one byte-identical image |
| `provenance` | 2 | Authorship, signatures, trailers — validated from the root commit on every run |
| `analyse` | 2 | PHPStan at `level: max` |
| `format` | 2 | Pint, check mode |
| `lint` | 2 | PHP_CodeSniffer |
| `audit` | 2 | `composer audit` |
| `tooling-spec` | 2 | The documented tool versions match the lockfile |
| `required-checks` | 2 | Live rulesets match `.github/protection/rulesets/*.json`, and `main`'s classic branch protection matches `.github/protection/branches/main.json` |
| `test` | 3 | PHPUnit, 100% line coverage floor |
| `mutation` | 3 | Infection, minimum MSI |
| `acceptance` | 3 | Behat, against the `prod` image |
| `contract-change` | 3 | A specification change is reviewed as a specification change |
| `openapi` | 4 | Generate and audit, failing on warnings |
| `licence` | 4 | Dependency licences against an allowlist, and `THIRD-PARTY-LICENCES.md` against the lockfile. The artifact exists now as `make licence`; only the job waits on the workflow |
| `red-before-green` | 4 | The named red SHA is an ancestor and was recorded red |

`acceptance` runs against the **`prod`** image, not `dev`, because
`APP_DEBUG=false` changes response bodies and the specification must describe
what is actually published.

The coverage floor is **flat at 100%**, not a ratchet. A ratchet exists to drag
legacy code upward; on a greenfield two-resource domain it is machinery that
quietly permits 61%. The mutation score is what stops a 100% line-coverage
floor being satisfied by assertion-free tests: a test that asserts nothing
executes lines but kills no mutants.

### Aids, which are not gates

- **AI Scan for pull requests.** Informs. Never required.
- **The reviewer checklist** in the pull request template. Informs. Nothing
  about it is enforced.
- **The git hooks** in `.githooks/`. `--no-verify` bypasses them, and an
  unhooked clone is fully protected, because CI runs the same script.

## Iterations

Five, two days each. **Scope is the variable; dates are not.**

| | Theme | Dates |
|---|---|---|
| 1 | Foundation | 24–25 Oct 2026 |
| 2 | The gate | 26–27 Oct 2026 |
| 3 | Executable specification | 28–29 Oct 2026 |
| 4 | The exemplar | 30–31 Oct 2026 |
| 5 | Release | 1–2 Nov 2026 |

A started iteration never has its dates or its title changed. A future one may
be re-dated **before it starts**, with the reason recorded in the preceding
retro.

All five were shifted two days earlier on 24 Oct 2026, before any of them had
started and before a single item existed, because the work had begun and the
board said otherwise. Re-dating costs nothing mechanically — an iteration keeps
its id across a date change, so item assignments survive — but it is recorded
here because a schedule that quietly tracks reality afterwards is worth less
than one that says when it moved.

Finishing early means pulling work forward *within the theme*, or landing
decision records — never pulling across a theme boundary. The themes are what
make "the gate matured across iterations" legible to someone reading the
history afterwards.

**If scope inflates: cut the feature, never the gate.**

Each iteration ends with a retro note and a signed annotated tag. Before the
tag, a fresh-context agent verifies the iteration's claims against a cold clone
and files its report as `docs/verification/v0.N.0.md` through a pull request.
Any claim found false blocks the tag.

## The board

Four columns — Todo, In progress, In review, Done. Commitment is carried by the
**Iteration** field rather than by Status, so "planned" and "where it is" stay
separate.

**The item is the work, not the pull request.** A delivery issue is one board
item and may be delivered by any number of pull requests; its Status tracks the
work, sitting in *In review* for as long as a pull request of its is open. The
alternative — one item per pull request — was tried for an afternoon and
abandoned: it counted a single unit of work two and three times against the
iteration, and it is not how anyone actually uses a tracker.

**A decision record is the exception**, because there is no issue behind it.
A decision is finished when its record lands on `main` through an approved pull
request, and for those the pull request *is* the whole unit, so it is the item.

An issue is **off the board** when its open sub-issues are themselves board
items, so a map attached to a delivery issue does not demote it. Wayfinder
decision tickets — `grilling`, `research`, `prototype` — are never items; the
pull request that ratifies what they decided is.

The backlog holds the current and next iteration only, and accretes as
decisions resolve. A backlog fully populated on day one is a waterfall plan in
agile costume, and an assessor reads that instantly.

## Protection

Applied from committed JSON by `make protection`, run by a human with an admin
token. No CI job applies it: an admin token in Actions secrets would hand admin
power to the implementer credential through the back door. CI checks read-only
that the live configuration still matches. See
[`.github/protection/`](../.github/protection/).

`main` is governed by two mechanisms, because GitHub splits them. The **gate**
is a ruleset with an empty bypass list, binding everybody. **Who may push** is
classic branch protection's `restrictions`, an allowlist holding the approver
alone — the only place GitHub expresses a permission rather than an exemption.

**Nobody bypasses anything.** An earlier arrangement put the push restriction in
a ruleset, which can only be built as a prohibition plus an exemption, so every
merge would have been logged as a bypass. [ADR 2](adr/0002-protecting-main.md)
records why that was retired and what was verified before trusting the
replacement.

## Limits, stated rather than engineered around

- Authorization and approval are the same person.
- Bypass-list drift is invisible to CI; `GET /rules/branches/main` does not
  return `bypass_actors` and `GET /rulesets/{id}` is redacted for a write-scoped
  token. Only a human reading the settings page can see it. Every bypass list
  here should read **empty**.
- A forged required status check still reports `success` to the combined-status
  API after pinning. The merge is blocked, but the Checks surface lies, so the
  per-iteration verification attempts the forgery rather than reading the tab.
- **The arrangement is organisation-dependent.** Push restrictions are not
  available on user-owned repositories. Moving this repository back under a user
  account would silently make the restriction inexpressible and force the bypass
  construction back.
- **`main` is governed by two mechanisms read from two endpoints.** A reader has
  to know both exist, and the drift check has to compare both.
- Check run conclusions expire after 90 days on a public repository. The
  durable record is the merge commit body, which is why the pull request
  template is written as an audit record.
- **The licence allowlist is measured-only.** It names the three licences
  present in the production tree today, so the first legitimate `BSD-2-Clause`
  or `ISC` dependency stops a build. That is the design working: the cost is
  one ticket, and the alternative is a list naming licences nobody chose.
- **Dev dependencies are outside the licence gate** (`--no-dev`), so a dev-only
  licence change is unchecked. Deliberate — dev tooling is never combined into
  the conveyed work — and recorded so that widening it later is a reversal
  rather than a gap being filled.
- There is no SAST for PHP.
- `required_signatures` on a tag ruleset does not verify the tag object — an
  unsigned annotated tag pushes fine. Signed-tag enforcement is a CI check, not
  a rule.
- Metadata restriction rules (`commit_message_pattern`, `tag_name_pattern`) are
  not available on this plan at all. Both are absorbed into CI.
