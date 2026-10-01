# Aggregate Google Tag Manager template

[![CI](https://github.com/Subschema-LLC/aggregate-gtm-tag-template/actions/workflows/ci.yml/badge.svg)](https://github.com/Subschema-LLC/aggregate-gtm-tag-template/actions/workflows/ci.yml)

A web-container template for initializing the [Aggregate browser SDK](https://github.com/Subschema-LLC/aggregate/blob/master/docs/TRACKING.md) and sending named events through `window.Aggregate.emit()` (or your configured tracker namespace).

## Before you start

Register a website in your Aggregate installation and obtain its **public website token**. Configure its allowed event-source domains for the website you are tracking. Do not use an organization sharing token or an administrative secret.

Use your installation's configured `/aggregate.js` route, which includes the saved data model's public collection settings. A raw GitHub or static CDN copy does not provide those settings. This template supports the default, case-sensitive `Aggregate` namespace as well as custom global object names configured via `js_namespace`.

## Initialize the SDK

1. In a GTM **Web** container, open **Templates → Tag Templates → New → Import** and import [template.tpl](template.tpl).
2. In the template editor, open **Permissions → Injects scripts**. Replace `https://analytics.example.com/*` with your Aggregate host, for example `https://stats.your-company.com/*`, then save the template. The host must match the **Aggregate script URL** used below.
3. Create an **Aggregate** tag with **Tag action** set to **Initialize SDK (automatic page view)** and fill in:

   | Field | Example | Purpose |
   | --- | --- | --- |
   | Aggregate script URL | `https://analytics.example.com/aggregate.js` | Configured SDK route; `/aggregate.js?min=1` and deployment path prefixes are supported. |
   | Collector endpoint | `https://analytics.example.com/api/receive` | HTTPS ingestion URL for your installation. |
   | Public website token | Your registered website's token | Identifies the website receiving events. |
   | Tracker global object name | `Aggregate` | Optional global window object name (default: `Aggregate`). Set to match `js_namespace` if customized. |

4. Fire this tag early, for example with **Initialization – All Pages**. Use one initialization tag and one endpoint/token configuration per page.

The template adds URL-encoded `endpoint` and `token` query parameters to the script URL. Enter the base SDK URL, optionally with `?min=1`; do not add configuration parameters yourself. The public token is visible in the script request URL.

The SDK automatically sends the initial page view, waiting for `DOMContentLoaded` when necessary. Use this initialization tag as the only SDK loader and configure the endpoint and token through its fields. No additional initial page-view tag is needed. Inline `Aggregate.endpoint` or `Aggregate.websiteToken` settings take precedence over the template's URL configuration.

GTM caches script injection by the complete configured URL, so repeated initialization with the same settings shares one load. Changing the URL, endpoint, or token creates a different load; keep the configuration stable throughout the page.

## Send events

Create another **Aggregate** tag with **Tag action** set to **Send event**. Set a fixed event name, such as `signup_click`, add any custom data, and choose the event's trigger.

Under **Advanced Settings → Tag Sequencing**, select the initialization tag as the setup tag and enable **Don't fire this tag if the setup tag fails or is paused**. This makes the event wait for SDK loading; an early initialization trigger alone does not guarantee an asynchronous script has finished. The initialization cache allows the same setup tag to be reused.

The event action calls `window[objectName].emit(eventName, properties, goalEvent)`, omitting optional arguments when none are configured. It requires the SDK to be initialized and fails if the method is missing or returns `false`. The SDK sends `properties` to the collector as the event's `customData` object (earlier SDK versions name it `eventData`).

### Custom data

An event's custom data can come from two places, and you can use either or both:

- **Custom data object**: a GTM variable that returns an object, such as a Data Layer Variable named `customData`.
- **Custom data properties**: a table of individual names and values, typed or taken from GTM variables.

The template combines them into one flat object. When a table row and the object use the same name, the row's value is sent. For example, with this data layer push:

```js
dataLayer.push({
  event: 'purchase_completed',
  customData: { plan: 'basic', amount: 49.5, trial: false }
});
```

a **Custom data object** of `{{DLV - customData}}` and a table row `plan` = `pro` send:

```json
{ "plan": "pro", "amount": 49.5, "trial": false }
```

The same rules apply to both sources:

- At most 50 unique property names in total, matching `[A-Za-z][A-Za-z0-9_.-]{0,63}`. Reserved prototype names are rejected; dots are literal characters, not nesting.
- Values must be strings, finite numbers, booleans, or `null`. The object must be flat: a nested object or array fails the tag rather than being flattened or partly sent. An object value that is `undefined` is skipped, as it would be in JSON.
- A blank, `undefined`, or `null` object setting sends no object properties. Any other value that is not an object, such as text, fails the tag.
- Use GTM variables to preserve numeric and boolean types in the table; text such as `"42"` remains a string.

GTM's data layer merges objects pushed under the same key, so properties from an earlier `customData` push can remain in the Data Layer Variable for later events. Push `customData: null` before an event's new object, or include every property in each push, when earlier values must not carry over.

### Event names and goals
The event action calls `window[objectName].emit(eventName, properties, goalEvent)`, omitting optional arguments when none are configured. It requires the SDK to be initialized and fails if the method is missing or returns `false`.

- Event names must match `[A-Za-z][A-Za-z0-9_.:-]{0,99}`: at most 100 characters, with no spaces. Use an approved taxonomy rather than names assembled from user input.
- Optional conversion goal codes must match `[A-Za-z][A-Za-z0-9_.:-]{0,63}`, corresponding to an enabled goal in your installation's `config/goals.yaml` (for example `signup` or `purchase`). It is passed as the third argument to the emit method.

The SDK and server apply the data model's consent, type, and collection filters. A property or goal accepted by the template can still be omitted by those filters. See the [SDK tracking guide](https://github.com/Subschema-LLC/aggregate/blob/master/docs/TRACKING.md) for property limits and goal configuration.

## Consent and permissions

Initialization leaves Aggregate's consent state unchanged; a fresh SDK starts with unknown consent and anonymous tracking. This template does not map GTM consent settings or grant enhanced consent. Connect your consent manager to Aggregate's consent API as described in the SDK documentation. Anonymous page views and named events can continue after rejection, subject to the server's collection rules.

The script permission ships with the example pattern `https://analytics.example.com/*`; replace the host with your installation's host during setup. GTM requires HTTPS, a hostname, and a path pattern; a hostname consisting only of `*` is invalid. You can narrow the path to `/aggregate.js*`, or `/metrics/aggregate.js*` for a deployment under `/metrics`. Keep the trailing `*` to allow the SDK configuration query parameters. Changing the tag's script URL does not update its template permission.

The template reads and executes `<objectName>.emit` (`Aggregate.emit` by default). If your installation uses a custom `js_namespace` (for example `CompanyAnalytics`), set **Tracker global object name** to `CompanyAnalytics` and add `CompanyAnalytics.emit` with read and execute access under template **Permissions → Accesses global variables** before saving.

Console logging is restricted to GTM preview/debug mode and requires the **Log failures to the console** checkbox.

## Verify before publishing

Run the imported template's tests in GTM, then use **Preview** to verify initialization and event sequencing. Confirm that the SDK loads once for a consistent configuration and that the initial page view is not duplicated.

Inspect `/api/receive` requests in browser DevTools, including response bodies. A successful GTM tag means the SDK loaded or accepted the event call; it does not confirm server ingestion. An HTTP 202 response can represent recorded data or intentionally ignored collection, and enhanced events may require a running server worker.

For local regression checks with Node.js 18 or later:

```sh
node --test tests/*.test.mjs
```

These tests use mocked GTM APIs. GTM's **Tests** tab and **Preview** remain necessary to verify the actual sandbox, permissions, deployment, and ingestion.

## Release versioning and tagging

This project uses a calendar-based versioning scheme for releases and Git tags:

```
v[YEAR].[MN].[INDEX]
```

- **`[YEAR]`**: 4-digit calendar year (e.g. `2026`).
- **`[MN]`**: 2-digit zero-padded calendar month (`01`–`12`, e.g. `09` for September).
- **`[INDEX]`**: 2-digit zero-padded release counter for that specific month (`01`, `02`, `03`…), **not** the day of the month.

### Examples

| Release Tag | Meaning |
| :--- | :--- |
| `v2026.09.01` | First release in September 2026 |
| `v2026.09.02` | Second release in September 2026 |
| `v2026.10.01` | First release in October 2026 |


```
v[YEAR].[MN].[INDEX]
```

- **`[YEAR]`**: 4-digit calendar year (e.g. `2026`).
- **`[MN]`**: 2-digit zero-padded calendar month (`01`–`12`, e.g. `09` for September).
- **`[INDEX]`**: 2-digit zero-padded release counter for that specific month (`01`, `02`, `03`…), **not** the day of the month.

### Examples

| Release Tag | Meaning |
| :--- | :--- |
| `v2026.09.01` | First release in September 2026 |
| `v2026.09.02` | Second release in September 2026 |
| `v2026.10.01` | First release in October 2026 |

### Repository structure and release files

- [template.tpl](template.tpl): GTM template fields, sandboxed code, permissions, and GTM tests.
- [tests/template.test.mjs](tests/template.test.mjs): Local regression test suite.
- [metadata.yaml](metadata.yaml): Community Template Gallery release history.
- [scripts/release.mjs](scripts/release.mjs): Release helper script to calculate the next monthly release tag.

### Release Workflow

1. **Verify**: Ensure local regression tests pass:
   ```sh
   node --test tests/*.test.mjs
   ```
2. **Commit Template Changes**: Finalize changes to `template.tpl` and other template assets.
3. **Check Next Version**:
   ```sh
   node scripts/release.mjs --next
   ```
4. **Update `metadata.yaml`**: Prepend a new entry with the template commit SHA and change notes prefixed with the release tag:
   ```yaml
   versions:
     - sha: <TEMPLATE_COMMIT_SHA>
       changeNotes: "v2026.09.01: Production release notes..."
   ```
5. **Tag & Publish**:
   Create and push the signed or annotated tag:
   ```sh
   git tag -a v2026.09.01 -m "Release v2026.09.01"
   git push origin v2026.09.01
   ```
   Pushing the tag triggers the automated [Release Workflow](.github/workflows/release.yml) to run tests, bundle release artifacts (`template.tpl`, `metadata.yaml`, `LICENSE`), and publish the GitHub Release.


## Contributing

Contributions are welcome! Please start working branches from `development` and target `development` when opening pull requests.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for our branching model, privacy invariants, and PR guidelines. All contributors are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

For security policies and vulnerability disclosure, please see [SECURITY.md](.github/SECURITY.md).

## License

This project is licensed under the [Apache License, Version 2.0](LICENSE).
