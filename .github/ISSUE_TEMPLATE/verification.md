---
name: Iteration verification
about: Fresh-context verification of an iteration's claims
title: 'Verify v0.N.0'
labels: ''
assignees: ''
---

<!--
  Executed by an agent with NO memory of the implementation, cloning the
  iteration's tag cold. This replaces a second reviewing agent on each pull
  request, which was considered and rejected: two agents directed by one person
  under one instruction set are correlated, not independent, and the value of a
  second reviewer is independence of judgement.

  An independent agent produces real signal when it verifies claims about the
  repository, rather than re-reading a diff written minutes ago.
-->

Tag under verification: `v0.N.0`

## Claims to test

- [ ] A clean clone into an empty directory runs `docker compose up -d` first try and the app answers
- [ ] The full gate is green, and each gate fails when given something it should reject
- [ ] `bin/check-provenance --all` validates the history from the root commit
- [ ] The live protection matches `.github/protection/`, **including a human reading every ruleset's bypass list** — CI cannot see `bypass_actors`, and every list should read empty
- [ ] A forged required status check does not merge: post a commit status named after a required context and confirm the merge stays blocked
- [ ] **The approver cannot merge an unapproved pull request.** The hinge of the whole arrangement. `current_user_can_bypass: never` asserts it, but that is the same class of evidence as the forged status that reported `success`, so attempt the merge rather than reading the field. Open a pull request, leave it unapproved, and confirm the approver's token is refused. If it is not, the gate's empty bypass list means nothing and the central claim of this repository is false
- [ ] **No merge is a bypass.** Rule insights for the period under verification contains no bypass entry, and the approver is offered an ordinary merge button rather than "Merge without waiting for requirements to be met"
- [ ] **The implementer still cannot merge an approved pull request.** Attempt it with the implementer token and confirm the refusal
- [ ] Every claim in this iteration's ADRs and README text is true of this tag

## What could not be verified

<!--
  Required, and not a formality. A verification that has never failed is
  indistinguishable from one that does not run, so a clean pass must say what
  it actively tried to break and what it could not reach.
-->

## Outcome

<!-- Any claim found false blocks this iteration's tag. -->
