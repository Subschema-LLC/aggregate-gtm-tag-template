# Contributing

Contributions to the Aggregate Google Tag Manager template are welcome. Start a branch
from `development` and target `development` when opening a pull request. See the
[README](README.md) for template setup and the main [Aggregate repository](https://github.com/Subschema-LLC/aggregate)
for server and SDK documentation.

Follow the [code of conduct](CODE_OF_CONDUCT.md). Report vulnerabilities privately
using the [security policy](.github/SECURITY.md); ordinary bugs and proposals belong in
[GitHub issues](https://github.com/Subschema-LLC/aggregate-gtm-tag-template/issues).

Coding agents should review the design principles and privacy invariants below for the
product ethos, architectural boundaries, and expectations for delivering changes.

## Branching strategy

Create each working branch from the latest `development`. Use a descriptive
prefix, for example `feature/add-property-mapping`, `issue/12-fix-script-permission`,
`fix/endpoint-validation`, `docs/update-gtm-guide`, or `chore/ci-dependencies`.
These branches are for individual changes; `development` and `main` are the shared
integration and release branches.

Changes move through these pull requests in order. On GitHub, **compare** is the
source branch and **base** is the target branch:

| Source (compare) | Target (base) | Purpose |
| --- | --- | --- |
| `feature/...`, `issue/...`, or working branch | `development` | Review and integrate a contributor's change |
| `development` | `main` | Promote integrated changes for production release |

Contributors open PRs against `development`, including when contributing from a
fork. Maintainers open the promotion PR from `development` to `main` after integration
and verification. Follow the same path for fixes found during testing: branch from
`development`, submit the fix to `development`, and promote it to `main` for release.

Each stage uses a PR and the relevant review and checks; keep individual changes
on working branches and preserve the promotion order. Google Tag Manager's Community
Template Gallery requires the published template to live on the `main` branch.

## Design principles

- **Strictly minimal permissions:** Only request permissions in `template.tpl` that are
  strictly required for the template's documented actions (`inject_script`, `access_globals`
  for `Aggregate.emit`, and `logging` in debug environments).
- **Runtime validation:** GTM editor validators only check static input in the UI; values
  supplied by GTM variables at runtime must be thoroughly validated by the sandboxed
  JavaScript runtime before calling window methods or injecting scripts.
- **Strict adherence to GTM Style Guide:** Maintain parameter naming (`lowerCamelCase`),
  sentence case labels, human-friendly descriptions, and Title Case display names.
- **Zero external dependencies:** The template runner and tests must remain lightweight,
  portable, and execute via Node.js's built-in test runner without bloating npm dependencies.

Contributions developed with AI coding agents are welcome. Apply your own
expertise and judgment: provide the project's context, guide the agent's
decisions, and review and test the complete change. Submit work you understand
and can explain, including its architectural, privacy, and licensing implications.
The author remains responsible for the contribution and for verifying the
behavior described in the PR.

## Privacy invariants

Treat these as constraints on implementation and documentation:

- **Anonymous mode has no person or session identifier.** Do not introduce visitor
  IDs, session IDs, fingerprints, or hashes derived from IP addresses and browser
  details. Do not attempt to map GTM identifiers (like Google Client ID) into anonymous
  Aggregate events.
- **Public website tokens only.** The template only accepts and handles public website
  tracking tokens, which are client-visible in network requests. Never configure organization
  sharing tokens or administrative API keys in GTM tags.
- **Event taxonomy enforcement.** Event names must match `[A-Za-z][A-Za-z0-9_.:-]{0,99}`
  (at most 100 characters, starting with a letter, no spaces). Use an approved, fixed
  taxonomy rather than assembling names from arbitrary user input.
- **Scalar properties only.** Custom data, from the object variable and the property
  table combined, is limited to at most 50 unique scalar keys matching
  `[A-Za-z][A-Za-z0-9_.-]{0,63}`. Values must be strings, finite numbers, booleans, or
  `null`; nested objects and arrays are rejected, not flattened. Reserved prototype names
  (`constructor`, `prototype`, `__proto__`) are rejected.
- **Enhanced collection needs explicit consent.** The template leaves Aggregate's consent
  state to the site's consent management platform (CMP) and SDK configuration. Tags must
  never synthesize consent or bypass Aggregate's consent API.

## Set up a development checkout

Use Node.js 18 or newer. No package installation is required to run the regression test suite.

After cloning, update `development` from its tracked upstream and create your
working branch:

```bash
git switch development
git pull --ff-only
git switch -c feature/your-change
```

If you cloned a fork, first sync its `development` with the main repository's
`development`. Set the PR's base repository to `Subschema-LLC/aggregate-gtm-tag-template` and its
base branch to `development`.

## Tests and checks

The [CI workflow](.github/workflows/ci.yml) runs all tests on Node.js 18, 20, and 22
on pushes and pull requests. Its final `CI` check requires all matrix jobs to pass.

Run the test suite locally from the repository root:

```bash
node --test tests/*.test.mjs
```

Verify formatting and git status:

```bash
git diff --check
```

Before opening a PR with template changes, also verify the template in Google Tag Manager:
1. Open GTM **Web** container → **Templates** → **Tag Templates**.
2. Import `template.tpl`.
3. Run all tests in the template editor's **Tests** tab.
4. Test tag execution in GTM **Preview** mode.

## Release versioning and tagging

Releases follow the CalVer convention:

```
v[YEAR].[MN].[INDEX]
```

- `[INDEX]` is the 2-digit zero-padded release counter for that month (`01`, `02`...), **not** the day.
- Use `node scripts/release.mjs --next` to compute the next release version tag.
- When publishing, commit the template changes, update `metadata.yaml` with the commit SHA and release notes, and tag the release commit. Pushing the tag triggers the [Release workflow](.github/workflows/release.yml) to package assets and publish the GitHub release.

## Preparing a pull request

For an individual contribution, select `development` as the base branch and your
working branch as the compare branch. Maintainer promotion PRs move from `development`
to `main`.

Keep the change focused and follow the conventions of the surrounding code.
Explain the concrete problem, the resulting behavior, and any permission or validation
implications. Include the checks you ran and their results.

Before submitting, review the complete diff for unintended changes, secrets,
and generated artifacts. Update documentation when behavior changes.

This project is licensed under the **Apache License, Version 2.0** under [LICENSE](LICENSE).
The [Code of Conduct](CODE_OF_CONDUCT.md) adapts Contributor Covenant 2.1 under **CC BY 4.0**.
Preserve these license notices.
