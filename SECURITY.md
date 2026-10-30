# Security policy

## Reporting a vulnerability

Report privately through GitHub's
[security advisory form](https://github.com/marcth-labs/proving-ground/security/advisories/new).
Please do not open a public issue.

This is a demonstration repository with no deployed environment and no users,
so there is nothing to compromise operationally. A report that the *pipeline*
can be subverted is the interesting kind and is very welcome — for example a
way to land a commit on `main` that `bin/check-provenance` accepts but should
not.

## Scope of the claims made here

This repository demonstrates an enforcement mechanism. It claims no compliance
with SOC 2 or any other framework. The implementer and approver credentials are
held by one person, so there is no independent review. See
[the README](README.md#honest-limits).

## Controls in place

| Control | Kind |
|---|---|
| Required pull request, one approving review, code-owner review | Platform gate |
| Push to `main` restricted to the approver by name | Platform gate |
| Signed commits required on every branch | Platform gate |
| Secret scanning and push protection | Platform gate |
| `bin/check-provenance` — authorship, signatures, trailers, from the root | Gate |
| Dependabot alerts, no auto-dismissal rules active | Detection |
| CodeQL, `actions` scope only | Detection |
| AI Scan for pull requests | Aid — never blocks |

**There is no SAST for PHP.** GitHub's CodeQL does not support the language,
and no equivalent is in place. Stated rather than papered over.

Every Dependabot alert is adjudicated by a human: no auto-triage preset is
enabled. The reasoning is in
[ADR 1](docs/adr/0001-implementer-and-approver-credentials.md) — vendor-managed
detection is acceptable, vendor-managed suppression is not.
