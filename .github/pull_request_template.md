<!--
  This body becomes the permanent merge commit message on main. It is the audit
  record, not a convenience form -- the pull request page can be edited after
  the fact and the commit cannot, so what matters is what is written here.
  Delete nothing; write "none" where a section does not apply.
-->

## What changed and why

<!-- Enough for a reader in a year with no access to this pull request page. -->

## Record

Refs: #
Decision: <!-- docs/adr/NNNN-slug.md + the map ticket, or `none` -->

<!--
  `Decision: none` is a legitimate value and must be written explicitly. A
  missing line is then always a defect rather than an ambiguity.
-->

## Evidence

<!--
  Which gates this change adds, and which it exercises. Name them; do not say
  "CI is green". A reader should be able to tell what was actually proved.
-->

## Reviewer aid

<!--
  AID, NOT A GATE. Nothing below is enforced, and ticking it proves nothing --
  it is a prompt for the reviewer's attention. The gates are the required
  status checks and the approval. An unlabelled checklist in a pull request
  template is a decoration that reads like a control, which is worse than no
  checklist at all.
-->

- [ ] The change does what the body says it does
- [ ] Any new gate fails when it should, not merely passes when it should
- [ ] Documentation that is now wrong has been corrected in this change
- [ ] No `Co-Authored-By:` trailer on any commit
