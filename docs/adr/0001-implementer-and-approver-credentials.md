# 1. Implementer and approver credentials

- **Status:** Accepted
- **Decided:** 2026-10-24
- **Ratified:** on the merge of [#22](https://github.com/marcth-labs/proving-ground/pull/22)
- **Tickets:** [#3](https://github.com/marcth-labs/proving-ground/issues/3), [#13](https://github.com/marcth-labs/proving-ground/issues/13), [#8](https://github.com/marcth-labs/proving-ground/issues/8)

## Context

This repository argues that every change to it was implemented by an agent and
approved by a human. An argument like that is worth nothing as a claim in a
README; it has to be a property a stranger can check from a clone.

The obvious way to describe the arrangement is "the agent does the work and the
human reviews it". That framing fails the first question an assessor asks, which
is not *who* but *how would I know*. It also quietly conflates two different
things, and keeping them apart is what made the rest of this repository
tractable.

## Decision

### Two roles, not two people

**Authorization** — which credential may do what — is separated from
**attribution** — what produced the content.

A credential holds the **implementer** role or the **approver** role.

| | Implementer | Approver |
|---|---|---|
| Authors non-merge commits | yes | no |
| Opens pull requests | yes | — |
| Approves | no | yes |
| Merges to `main` | no | yes |
| Creates release tags | yes | — |
| Repository admin | **no** | yes |

The rule, stated once:

> Every non-merge commit reachable from `main` is authored under a credential
> holding the implementer role and carries a `Generated-By:` trailer. Merging
> requires an approver credential, and the approver must differ from the author.

That last clause is the whole decision. Without it the arrangement is a
mechanism for labelling commits; with it, it is separation of duties.

### The account is a credential boundary, not an actor

`proving-ground-ai-agent` (id `347050697`) is not "the AI". It is a credential
with a role attached, and today it is one of two credentials held by one person.
Nothing about the arrangement assumes the implementer is an agent or that the
approver is a human; those are facts about how this repository is operated, not
about how it is enforced.

Keeping this straight is what lets `Generated-By:` mean something specific.
The commit author says *under which authority* the change landed. The trailer
says *what produced it*. An agent run under a human's credential, or a human
typing under the implementer credential, are both describable, and both are
visible rather than hidden.

### How each half is enforced

**Authorization is enforced by the platform.** The implementer credential is
`admin: false`, so it is structurally incapable of editing the protection
configuration or exempting itself from it, and `main` only accepts a push from
the approver. The implementer therefore cannot land even a fully approved pull
request. How that is configured, and why it took two mechanisms rather than
one, is [ADR 2](0002-protecting-main.md).

**Attribution is enforced by CI**, through
[`bin/check-provenance`](../../bin/check-provenance), which validates the full
history from the root commit on every run. It is a consistency rule in both
directions:

```
non-merge commit  MUST be authored by an implementer credential, signed by that
                  credential's key, Conventional Commits subject, Refs: #NN,
                  one well-formed Generated-By trailer
merge commit      MUST NOT be authored by an implementer credential
                  MUST NOT carry Generated-By
any commit        MUST NOT carry Co-Authored-By
```

The second direction is the one that earns its keep. A commit carrying
`Generated-By:` but **not** authored by an implementer is a false provenance
claim, and a presence-only check would wave it through. It is also what makes
the approver role checkable rather than asserted: a merge commit authored by the
implementer fails the check.

Signatures verify **offline**. `.github/allowed_signers` is committed, so
`git log --show-signature` works from any clone, with no network call, and
outlives the accounts. GitHub's Verified badge is a convenience; the committed
file is the evidence.

### Gate, aid, platform gate

Deciding which security features to adopt kept running into the same
ambiguity, so the vocabulary is fixed here and used throughout:

- A **gate** blocks. It is in the required-check list, it fails closed, and its
  definition lives in this repository.
- A **platform gate** blocks, but its definition lives with the vendor.
- An **aid** informs. It never blocks, and it must be *labelled* as an aid
  wherever it appears.

The rule that follows: **an aid presented as a gate is decoration**, and
decoration in a change-management trail is worse than an absence, because it
reads as a control to anyone skimming.

### What that taxonomy decided

| Feature | Verdict | Why |
|---|---|---|
| Agentic autofix | **Refused** | It authors commits. Any tool authoring commits reachable from `main` needs a role and a trailer; this one has neither. |
| Copilot Autofix | **Refused** | Same reason. |
| CodeQL | **Adopted**, `actions` scope only, **default setup** | GitHub's documented language support excludes PHP, so it is an Actions-workflow scanner here and is described as one. Default setup rather than advanced, because advanced would commit a `codeql.yml` that no implementer authored. |
| AI Scan for pull requests | **Adopted as an aid** | Never a required check. Labelled as an aid wherever it appears. |
| Secret scanning + push protection | **Adopted** | A platform gate, and named as one. |
| Dependabot alerts | **Adopted** | Detection. |
| Dependabot auto-triage preset | **Refused** | See below. |
| Dependabot version-update PRs | **Deferred** | Off until `provenance` is a required status check. After that a red Dependabot pull request is *evidence a control fires*, which is worth having. |
| PHP SAST | **None exists** | Stated plainly rather than papered over. |

### Vendor-managed detection is acceptable; vendor-managed suppression is not

The auto-triage preset was first refused on the grounds that it "silently
dismisses" alerts. That was wrong, and the correction matters: Dependabot
auto-triage dismisses with a recorded reason and the alerts stay retrievable. It
is auto-adjudication, not concealment.

The decision stands on a better argument. The rule is **"Managed by GitHub"** —
its predicate for *low-impact* and *development-scoped* is vendor-defined and can
be redefined with no pull request, no review, and no entry in this repository's
trail. A control whose definition lives outside the change-management record is
exactly what this repository exists to notice.

Unqualified, that argument would prove too much: secret-scanning patterns and
CodeQL queries are vendor-managed too. The line that holds is the heading above.
Detection improving is strictly good. Suppression broadening means the vendor
decides what you no longer see.

A reason specific to this codebase reinforces it: a large share of the
dependency surface here is `require-dev` — PHPStan, Pint, PHPCS, Infection,
PHPUnit, Behat, Guzzle — so the preset would suppress much of the alert surface
on a repository whose purpose is to show controls operating in the open.

### Forward-binding is procedural

This ADR does not ban future tools. **Any tool that authors commits reachable
from `main` requires a new ADR superseding this one.** A standing ban would be
dishonest about how decisions actually get made here, and would be ignored the
first time it was inconvenient. A superseding ADR is cheap, reviewable, and
leaves a record.

## Consequences

**Good.**

- "Is admin bypass disabled?" has a precise answer: **there is no bypass
  anywhere in this repository.** The approver merges by permission, not by
  exemption. See [ADR 2](0002-protecting-main.md).
- Provenance verifies from a clone with no network and no GitHub account.
- The approver's act lands *in the artifact* — the merge commit — rather than
  only in GitHub's review database.

**Costs, accepted.**

- **A rule can only be tightened if the existing history already satisfies it.**
  `check-provenance` validates from the root, and history cannot be rewritten
  once `non_fast_forward` is active. Loosening is always possible; tightening may
  not be. This is the forcing function that makes convention drift visible.
- **Merge commits are attested by GitHub only.** They are GPG-signed by
  `web-flow`, and `gpg.ssh.allowedSignersFile` covers SSH only, so the check
  exempts them from signature verification. The asymmetry is stated rather than
  hidden — and it is the right way round, since the implementer's work is what
  needs independent attestation and the approval is already recorded by the
  platform that enforced it.
- **Both roles are held by one person.** This repository demonstrates the
  enforcement mechanism and claims no compliance with any framework. See
  [`docs/way-of-working.md`](../way-of-working.md).
- **Bypass-list drift is invisible to CI.** `GET /rules/branches/main` does not
  return `bypass_actors`. Only a human reading the settings page can see it, so
  the per-iteration verification must. What it reads should be **empty
  everywhere**; see [ADR 2](0002-protecting-main.md).

## Alternatives rejected

**One credential, with the agent labelled by trailer alone.** Simpler, and it
gives up the entire argument: nothing would prevent the same credential
authoring and merging, so "approved" would be a convention.

**Squash merges.** Rejected on a fact rather than a taste. GitHub squashes
server-side with no access to the implementer's private key, so it re-signs with
its own `web-flow` key. After squash-merging every pull request, `main` would
contain **zero** commits signed by the implementer, while "require signed
commits" stayed green the whole time — a control reporting healthy over a
hollowed-out claim. Rebase merges have the same defect.

**A second reviewing agent on each pull request.** Rejected as correlated rather
than independent: two agents directed by one person under one instruction set
share judgement and interest, and claiming that as two-person review is exactly
the overclaim this repository must avoid. Replaced by **per-iteration
fresh-context verification**, where an independent agent checks out a tag cold
and tests the repository's claims rather than re-reading a fresh diff.
