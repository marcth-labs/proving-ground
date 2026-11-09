# Architecture decision records

One decision per file, numbered, never edited after ratification except to mark
them superseded. **Reasoning lives here and nowhere else**; `CONTEXT.md`,
`docs/way-of-working.md` and `AGENTS.md` carry a one-line statement and a link.

A decision earns an ADR if it clears all three tests:

1. **Hard to reverse.** Undoing it costs more than making it did.
2. **Surprising without context.** A competent reader would ask "why on earth".
3. **A genuine trade-off.** Something real was given up.

A decision is **ratified** when its record lands on `main` through an approved
pull request — not when its tracking issue closes. Each ADR records when it was
decided, and cites the pull request that ratified it. The citation rather than a
date, because a file cannot carry the timestamp of the merge that lands it, and
a date typed in beforehand is a prediction dressed as a record.

| | Decision | Status |
|---|---|---|
| [1](0001-implementer-and-approver-credentials.md) | Implementer and approver credentials | Accepted |
| [2](0002-protecting-main.md) | Protecting `main`: a permitted merge, not a bypass | Accepted |
| [3](0003-outbound-licence-and-the-dependency-allowlist.md) | The outbound licence, and the dependency allowlist that follows from it | Accepted |
