# 2. Protecting `main`: a permitted merge, not a bypass

- **Status:** Accepted
- **Decided:** 2026-10-26
- **Ratified:** on the merge of [#22](https://github.com/marcth-labs/proving-ground/pull/22)
- **Tickets:** [#10](https://github.com/marcth-labs/proving-ground/issues/10), [#17](https://github.com/marcth-labs/proving-ground/issues/17)
- **Supersedes:** the protection mechanism described in [ADR 1](0001-implementer-and-approver-credentials.md), which now points here

## Context

[ADR 1](0001-implementer-and-approver-credentials.md) fixes the roles: the
implementer authors and cannot merge, the approver merges and cannot author.
This ADR is about the half of that which the platform has to enforce — who may
put a commit on `main` — and about a construction that enforced it correctly
while producing the wrong evidence.

The first implementation used two rulesets, because **bypass lists are
per-ruleset**. `main-gate` carried the review requirements with an empty bypass
list, so it bound everybody including administrators. A second ruleset,
`main-push-restriction`, carried a single `update` rule bypassed only by
Repository admin. The implementer therefore could not land even a fully
approved pull request, and the approver could.

It worked. The problem is what it looked like from outside.

A ruleset **cannot express a permission.** There is no rule type meaning
*"these principals may push"*. The only construction available is a prohibition
plus an exemption, so the approver does not merge *despite* the rules — they
merge *through a hole in* them. GitHub renders this honestly and unhelpfully:
the only button offered on an approved pull request is *"Merge without waiting
for requirements to be met (bypass rules)"*, and every merge for the life of the
repository would be recorded in rule insights as a bypass.

This was found by looking at a real approved pull request
([#16](https://github.com/marcth-labs/proving-ground/pull/16)), not by reading
the configuration. The ticket that built the construction verified that the
approver *could* merge; it never asked what the only available path was called.

The claim that construction supports is: *"exactly one bypass exists in this
repository, it is bypassable only by the approver, it exempts nobody from any
gate, and all it does is distinguish the two roles."* Every word of that is
true. It also costs a paragraph of explanation at precisely the moment a reader
is deciding whether to believe anything else here, and it asks them to accept
that a thing labelled "bypass" is not one. An audit trail that needs a footnote
to be read correctly is a weaker artifact than one that does not.

## Decision

**`main`'s push restriction moves to classic branch protection, and
`main-push-restriction` is retired. No bypass exists anywhere in this
repository.**

Classic branch protection has the rule rulesets lack. `restrictions` is an
**allowlist** — *these principals may push to this branch* — and it is the only
expression of that idea GitHub offers. The approver is on it. Everybody else is
refused, administrators included, because `enforce_admins` is on.

The configuration is committed as
[`.github/protection/branches/main.json`](../../.github/protection/branches/main.json)
and applied by `make protection` from a human's shell, under the same rule as
the rulesets beside it: no setting is clicked, and no CI job holds an admin
token.

**Nothing is duplicated.** The gate — pull request required, one approving
review, code-owner review, stale-review dismissal, last-push approval, thread
resolution, merge commits only, signatures, no deletion, no force-push — stays
in `main-gate` and appears nowhere else. The classic protection carries
`restrictions` and nothing else; its three other top-level fields are `null`.
Two mechanisms, one responsibility each, no field defined twice.

### This reverses "no classic branch protection, ever"

[#10](https://github.com/marcth-labs/proving-ground/issues/10) ruled classic
protection out entirely. That ruling was sound when it was made and is wrong
now, for a reason that is recorded rather than quietly dropped.

#10's stated justification — that classic protection is less scriptable — was
already identified as wrong in its own ADR. Its real justification was that
*user, app and team restrictions are only available for organization-owned
repositories*, and the repository was then owned by a user. There was no
allowlist to reach for, which is exactly why a bypass had to be constructed.

The repository moved to the `marcth-labs` organisation on 2026-10-26. The
constraint that forced the construction no longer holds, so the construction
goes. GitHub's documentation confirms the move costs nothing: branch
restrictions are available in public repositories owned by a Free organisation.

### Verified, not asserted

The claim bought here — from *"one bypass exists"* to *"no bypass exists"* — is
strictly stronger, so it was demonstrated against this repository before being
written down. #10's forged-status finding is the precedent: an API field
reporting green over a broken control is a thing that has already happened
here once.

| | Claim | Result |
|---|---|---|
| 1 | The implementer cannot merge an approved pull request | `405 You're not authorized to push to this branch` — and now for the restriction's own reason, with no ruleset involved |
| 2 | The approver can merge an approved pull request, as a permitted act | `mergeable_state` moved from `blocked` to `clean`; merge performed with no bypass recorded |
| 3 | `enforce_admins: true` does not lock the approver out | It does not. `restrictions` is an allowlist and the approver is on it; the two settings answer different questions |
| 4 | The approver cannot merge an **unapproved** pull request | `405 At least 1 approving review is required` — the hinge of the whole arrangement, and never tested under either construction until now |

Claim 4 is the one that matters most and the one that had never been tested.
Both constructions *asserted* it through `current_user_can_bypass: never`, which
is the same class of evidence as the forged status that reported `success`.

## Consequences

**Good.**

- *"Is there a bypass?"* is answerable with one word. No footnote, no appeal to
  what the button is really doing.
- Rule insights stay empty, so a bypass appearing in them is signal rather than
  noise. Under the old construction every merge was an entry and a real bypass
  would have been invisible in the crowd.
- The dangerous field becomes drift-checkable. `GET
  /branches/main/protection` returns `restrictions` in full, whereas `GET
  /rules/branches/main` does not return `bypass_actors` and `GET /rulesets/{id}`
  is redacted. Moving the allowlist out of a bypass list moved it from the blind
  spot into CI's view.

**Costs, accepted.**

- **`main` is governed by two mechanisms, read from two endpoints.** The
  `required-checks` gate has to compare both, and a reader has to know both
  exist. This is the price of a platform that puts the allowlist in one system
  and everything else in the other.
- **The arrangement is now organisation-dependent.** Move the repository back
  under a user account and the restriction silently ceases to be expressible.
- **It will shortly need to cover a second ref.** An integration branch is
  under decision, and a gate that covers `main` but not the branch feeding it
  is a back door rather than a gate. Both the ruleset conditions and
  `branches/` gain an entry, which is cheap — but it is cheap only for as long
  as somebody remembers that protection is per-ref.
- **The ruleset bypass list is still invisible to CI**, so the per-iteration
  verification still needs a human to read it. What changed is that it should
  now read **empty everywhere** — a stronger and simpler thing to check than
  "empty except one entry that is fine".

## Alternatives rejected

**Keep the two-ruleset construction and explain it.** It was explained, in three
places, and the explanation was correct. Rejected because a control that reads
as its own violation is a bad artifact regardless of how well it is documented,
and because the explanation competed for attention with the claims that needed
it more.

**Duplicate the review requirements into classic protection and retire
`main-gate`.** Tempting, since it would leave one mechanism. Rejected: rulesets
express strictly more (`required_signatures` across all branches, tag
protection, merge-method restriction), so `main-gate` cannot be retired anyway,
and duplicating the gate into a second system would create two definitions of
one control that can drift apart silently — the defect this repository exists
to notice.

**Put the approver in a team and restrict to the team.** No present value: one
approver, one entry. It is the obvious change if a second approver is ever
added, and nothing here forecloses it.
