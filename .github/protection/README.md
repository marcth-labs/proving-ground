# Protection

The declarative source for this repository's branch and tag protection. `make
protection` applies it; nothing else should. A clicked setting is a change with
no diff, no review and no entry in the trail, which is the thing this repository
exists to notice.

No CI job applies these. Doing so would need an admin token in Actions secrets,
and that would hand admin power to the implementer credential through the back
door -- defeating the whole arrangement below. They are applied from a human's
shell with a human's token, and CI checks read-only that the live configuration
still matches these files.

| File | What it does |
|---|---|
| `rulesets/main-gate.json` | The gate. Pull request required, one approving review, code-owner review, stale reviews dismissed on push, last-push approval, threads resolved, merge commits only. Deletion, force-push and unsigned commits refused. Bypass list **empty**. |
| `rulesets/release-tags.json` | Tags cannot be deleted or moved once created. `creation` is deliberately absent. |
| `rulesets/all-branches-signing.json` | Unsigned commits are unpushable anywhere, not just to `main`. |
| `branches/main.json` | Classic branch protection. Its only job is `restrictions`: who may push to `main`, and therefore who may merge. |

## Why the push restriction is classic protection and not a ruleset

**A ruleset cannot express a permission. It can only express an exemption.**

There is no ruleset rule meaning *"these principals may push"*. The nearest
construction is an `update` rule -- *"nobody may update this ref"* -- with the
approver in the ruleset's `bypass_actors`. That works, and it is what this
repository shipped first. It also means the approver merges **by bypassing a
rule, every time, for the life of the repository**, and GitHub records it as
such: the only button offered is *"Merge without waiting for requirements to be
met (bypass rules)"*, and each merge lands in rule insights as a bypass.

On a repository whose entire argument is that nobody bypasses anything, that is
the wrong artifact. The claim available under that construction was *"one bypass
exists, and all it does is distinguish the two roles"* -- true, defensible, and
requiring a paragraph of explanation at exactly the point a reader is deciding
whether to believe anything else here.

Classic branch protection has the rule that rulesets lack. `restrictions` is an
**allowlist**: the approver is permitted, and everybody else -- administrators
included, because `enforce_admins` is on -- is refused. The approver's merge is
now an ordinary, permitted act. **There is no bypass anywhere in this
repository.**

The cost is that `main` is governed by two mechanisms rather than one, and they
are read back from two different endpoints. That is the trade, and it is taken
because the alternative corrupts the central claim. Nothing is duplicated
between them: the gate lives in `main-gate` and only there, the restriction
lives in `branches/main.json` and only there, and GitHub applies both.

This was only possible once the repository moved to an organisation. User, app
and team restrictions are not available on user-owned repositories, which is why
the bypass construction was reached for in the first place. See
[ADR 2](../../docs/adr/0002-protecting-main.md).

## Why `enforce_admins` does not lock the approver out

`enforce_admins: true` subjects administrators to the protection, and the
approver is an administrator. It does not lock them out, because `restrictions`
is an allowlist and the approver is on it -- the two settings answer different
questions. This was verified live rather than reasoned about: see the evidence
block on the pull request that introduced it.

## Required status checks, and why they are not here yet

`main-gate` carries no `required_status_checks` rule at commit zero, because a
required context naming a job that does not exist blocks every merge forever.
Each context is added in the same pull request as the job that produces it.

When they are added, every context must carry `integration_id` pinning it to
GitHub Actions. This is not hygiene. An **unpinned required status check is
forgeable by the implementer credential**: check *runs* require a GitHub App,
but commit *statuses* do not, and a required context matches by name across
both. A token with `repo` scope can `POST /repos/{owner}/{repo}/statuses/{sha}`
with the context name and `state: success`, and the pull request becomes
mergeable with no workflow having run. This was demonstrated on a throwaway
repository, not reasoned about.

Pinning closes it. The sting worth knowing: after pinning, the combined-status
API still reports `success` for the forged status, so **a forgery is invisible
to inspection and shows up only when a merge is attempted.** That is why the
per-iteration verification attempts the forgery rather than reading the Checks
tab.

## What this cannot see

The rulesets have an empty bypass list and the drift check cannot prove it.
`GET /rules/branches/main` does not return `bypass_actors`, and `GET
/rulesets/{id}` is redacted for a write-scoped token. A bypass list that grew an
entry would therefore be invisible to CI, so the per-iteration verification must
cover it by having a human read the settings page.

Classic branch protection does not have this hole: `GET
/branches/main/protection` returns `restrictions` in full to a token that can
read it, so the allowlist itself is drift-checkable. The asymmetry is worth
noting -- the mechanism that carries the dangerous field is the one CI can see.
