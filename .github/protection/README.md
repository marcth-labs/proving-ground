# Rulesets

The declarative source for this repository's branch and tag protection. `make
rulesets` applies them; nothing else should. A clicked setting is a change with
no diff, no review and no entry in the trail, which is the thing this repository
exists to notice.

No CI job applies these. Doing so would need an admin token in Actions secrets,
and that would hand admin power to the implementer credential through the back
door -- defeating the whole arrangement below. They are applied from a human's
shell with a human's token, and CI checks read-only that the live configuration
still matches these files.

| File | What it does |
|---|---|
| `main-gate.json` | The gate. Pull request required, one approving review, code-owner review, stale reviews dismissed on push, last-push approval, threads resolved, merge commits only. Deletion, force-push and unsigned commits refused. |
| `main-push-restriction.json` | A single `update` rule that only Repository admin bypasses. |
| `release-tags.json` | Tags cannot be deleted or moved once created. `creation` is deliberately absent. |
| `all-branches-signing.json` | Unsigned commits are unpushable anywhere, not just to `main`. |

## Why `main` is split across two rulesets

Bypass lists are **per-ruleset**, and that is the whole trick.

`main-gate` has an **empty bypass list**, so it binds everyone including
administrators. `main-push-restriction` carries the only bypass in the
repository: Repository admin may perform `update` on `main`.

The effect is that the approver can merge an approved pull request and nobody,
approver included, can get anything onto `main` that has not been through the
gate. The implementer holds `write` but not `admin`, so it cannot land even a
fully approved pull request -- it is structurally incapable of being the one who
merges its own work.

This also makes "is admin bypass disabled?" a question with a precise answer
rather than a judgement call: **the bypass list of the gate is empty, and the
only bypass in the repository is the one that distinguishes the approver role
from the implementer role, exempting nobody from any gate.**

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

`GET /rules/branches/main` does not return `bypass_actors`. The field an
attacker would change is the one the drift check cannot read. A write-scoped
token can read `GET /rulesets/{id}`, but the response is redacted. Bypass-list
drift is therefore detectable only by a human reading the settings page, and the
per-iteration verification must cover it explicitly. Stated here rather than
engineered around.
