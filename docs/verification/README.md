# Verification reports

One report per iteration, produced by an agent with **no memory of the
implementation**, cloning that iteration's tag cold.

The report lands here through a pull request rather than as an issue comment,
because a record is ratified only when it reaches `main` through an approved
pull request — and an issue comment is exactly the editable, unsigned,
one-person artifact that rule rejects.

Every report must state **what it could not verify**, and must record the
result of actively attempting to break a control. A verification that has never
failed is indistinguishable from one that does not run. Any claim found false
blocks that iteration's tag.
