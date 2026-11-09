# Proving Ground

A reference repository demonstrating an **auditable, agent-implemented,
human-approved delivery pipeline**.

Every commit here was authored by an agent credential, signed, and landed on
`main` only through a pull request a human approved. The claim is not that this
is a good way to build an API. It is that the trail is checkable — from a
clone, offline, by someone who does not trust the person who wrote this
sentence.

**The application is not the point.** It is a small health-reporting HTTP API,
and it exists so the pipeline has something real to operate on. The pipeline,
the gates, and the change-management trail are the deliverable.

## Run it

```sh
git clone https://github.com/marcth-labs/proving-ground.git
cd proving-ground
docker compose up -d --wait
curl localhost:8080/api
```

No PHP and no Composer on your machine, and no setup step. If that is ever
untrue, it is a defect rather than a documentation gap.

```sh
make help          # every gate is a target here
make setup         # wire up hooks and offline signature verification
make provenance    # verify every commit from the root
make licence       # dependency licences, against an allowlist and an inventory
make down
```

## Check the trail yourself

Signatures verify **offline**, against a key committed to this repository, with
no network call and no GitHub account:

```sh
git config gpg.ssh.allowedSignersFile .github/allowed_signers
git log --show-signature
```

Then the arrangement itself:

```sh
./bin/check-provenance --all
```

It validates the whole history from the root commit, in both directions:
every non-merge commit is authored by an implementer credential and signed by
it; every merge commit is authored by somebody else. A commit carrying a
`Generated-By:` trailer but **not** authored by an implementer is a false
provenance claim, and the check fails on it.

Two things you can confirm without running anything:

- The root commit's tree is `4b825dc642cb6eb9a060e54bf8d69288fbee4904`, git's
  canonical empty tree. It is the only commit here no pull request reviewed —
  no pull request can target a branch that does not exist yet — so that one
  exception was spent on a commit that introduces nothing. One hash to compare,
  rather than trust.
- `git log --first-parent main` is one entry per approved pull request.

## Guided tour

<!--
  Iteration 5. Five files in a fixed order, each proving one thing, so a
  reader can walk requirement -> specification -> issue -> pull request -> tag
  end to end. Written last, deliberately: it describes what the repository
  turned out to be.
-->

Not written yet. It arrives in iteration 5, once there is a complete
requirement → specification → issue → pull request → tag chain to walk.

## How it works

| | |
|---|---|
| [`CONTEXT.md`](CONTEXT.md) | What the terms mean |
| [`docs/way-of-working.md`](docs/way-of-working.md) | How a change reaches `main`, and the gate table |
| [`docs/adr/`](docs/adr/) | Why — the reasoning, each decision in exactly one place |
| [`AGENTS.md`](AGENTS.md) | The same rules in imperative form, for agents |
| [`docs/research/`](docs/research/) | What was found, and how each claim was established |
| [`.github/protection/`](.github/protection/) | The protection configuration, as committed JSON |

## Honest limits

This repository claims **no compliance** with SOC 2 or any other framework, and
would not satisfy one. The most important reason is stated up front:

**Both credentials are held by one person.** The implementer and the approver
are two GitHub accounts controlled by the same individual. What is demonstrated
is the enforcement mechanism — the approval is genuinely required by the
platform, the approver's act lands in the artifact as a merge commit, and the
implementer account is `admin: false` and so structurally unable to merge its
own work. What is *not* demonstrated is independent review, because there is no
second party.

Further limits, each recorded where it bites rather than collected into a
disclaimer: see the end of
[`docs/way-of-working.md`](docs/way-of-working.md#limits-stated-rather-than-engineered-around).

## Stack

PHP 8.5 · Laravel 13 · FrankenPHP · MariaDB 11 · Redis 7 · Docker Compose.

The PHP version is fixed as a **rule, not a number**: the newest PHP minor that
the current Laravel major supports and that the full gate chain tests against.
Laravel 13 caps PHP at 8.5, so "latest PHP" and "Laravel 13" stop being
compatible goals the moment 8.6 ships. Fixing the rule is what keeps this from
looking careless in a month.

## Licence

Copyright © 2026 111210793 Canada Inc.

This program is free software: you can redistribute it and/or modify it under
the terms of the **GNU General Public License** as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version. See [`LICENSE`](LICENSE) for the full text.

Relicensed from MIT on 31 Oct 2026; the reasoning, and the narrow thing GPLv3
actually buys a repository with no deployed environment, are in
[ADR 3](docs/adr/0003-outbound-licence-and-the-dependency-allowlist.md).

Dependency licences are a separate question and a separate gate. The
production tree is inventoried in
[`THIRD-PARTY-LICENCES.md`](THIRD-PARTY-LICENCES.md) — an inventory, not a
NOTICE, and it says so — and `make licence` fails on drift against the
lockfile or on a dependency off the allowlist.
