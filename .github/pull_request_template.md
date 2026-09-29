<!--
Read CONTRIBUTING.md before opening a PR. Create working branches from development
and target development. Maintainer promotion PRs go development -> main.
Use synthetic examples and redact credentials, tokens, raw analytics events,
personal data, and screenshots.
For suspected vulnerabilities, follow SECURITY.md before opening a public PR.
-->

## Problem and resulting behavior

<!-- Explain the concrete problem and what this change does. Link related issues. -->

## Validation

<!-- List relevant checks and results, including checks you could not run.
For GTM template changes, note local node test results, GTM template editor Tests tab, and Preview mode verification. -->

## Privacy and operational impact

<!-- Include only the points that apply; write "None" if none apply.
- Permissions: any changes to inject_script, access_globals, or logging.
- Runtime validation: checks for values supplied by GTM variables at runtime.
- Data model / taxonomy: event name, property limits, or sanitization rules.
- Documentation: updated README or template help text.
-->

- [ ] I reviewed the complete diff for secrets, personal data, and unintended or generated files.
- [ ] I preserved the project's license notices and considered any added dependencies' licenses.
- [ ] I ran the test suite and confirmed all checks pass: `node --test tests/*.test.mjs`.
