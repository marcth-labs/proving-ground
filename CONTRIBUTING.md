# Contributing

This is a demonstration repository, and its history is the artifact. That makes
contribution unusual, so the position is stated plainly rather than left for
you to discover in a failed check.

## What is welcome

**Issues.** Especially ones that say a claim made here is false, that a gate
does not gate, or that a control is decoration. That is the most useful thing
anyone can contribute, because the repository's whole argument is that its
claims are checkable.

**Questions** about why something was decided the way it was. If the answer is
not already in [`docs/adr/`](docs/adr/), the ADR is incomplete and that is
worth knowing.

## What cannot be accepted as-is

**Pull requests from outside collaborators cannot be merged.** Not a judgement
on the contribution — it is structural. Every non-merge commit reachable from
`main` must be authored under a credential holding the implementer role and
must be signed by a key in
[`.github/allowed_signers`](.github/allowed_signers). `bin/check-provenance`
validates this over the full history on every run, so a commit from an
unlisted credential turns the check red permanently, and the history cannot be
rewritten to fix it.

If you want to propose a change, open an issue describing it. If it is right,
it gets implemented and attributed to you in the pull request body and the
changelog.

## Working in a clone

```sh
docker compose up -d --wait
make setup
make help
```

There is no PHP or Composer on the host and none is needed. Run PHP through
`make` targets or `docker compose exec app`.

Before committing anything, read [`AGENTS.md`](AGENTS.md). It applies to humans
too — it is simply written in imperative form because most of the commits here
are made by an agent. The rules that bite first:

- Set your commit identity repo-locally, never globally.
- Never add a `Co-Authored-By:` trailer.
- Conventional Commits subject, `Refs: #NN`, one `Generated-By:` trailer.

`make setup` installs a `commit-msg` hook that catches these before they cost
you a round trip. It is an aid: `--no-verify` bypasses it, and CI runs the same
script, so an unhooked clone is fully protected.

## Reporting a security issue

See [`SECURITY.md`](SECURITY.md). Do not open a public issue.
