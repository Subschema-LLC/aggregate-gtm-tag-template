# AGENTS.md

This repository follows [FIDES](https://github.com/Subschema-LLC/FIDES-Architecture)
where it applies. The deliverable here is a Google Tag Manager template
(`template.tpl`) with its metadata, tests and release scripts, not an
application, so the FIDES zones do not map onto this repo. The directives
that govern work here:

- The template is one deliverable: keep it small, readable top to bottom,
  and self-contained. Supporting code (tests, scripts) stays in small files
  with one job each.
- The template does only what its parameters and permissions declare: no
  network calls, storage or data access beyond what the template's
  permissions section grants.
- No secrets, account ids or client data in the template, tests or
  examples. Anything environment-specific is a template parameter, never a
  hard-coded value.
- A change to what the template collects or sends is a behavior change:
  name every intended difference in the pull request, and update the tests
  in `tests/` with the change.
- Comments say what is true now. History goes in the commit message.
- Run the repo's tests before you finish; they must pass.
