# Aggregate Google Tag Manager template

A web-container template for initializing the [Aggregate browser SDK](https://github.com/Subschema-LLC/aggregate/blob/master/docs/TRACKING.md) and sending named events through `window.Aggregate.emit()`.

## Before you start

Register a website in your Aggregate installation and obtain its **public website token**. Configure its allowed event-source domains for the website you are tracking. Do not use an organization sharing token or an administrative secret.

Use your installation's configured `/aggregate.js` route, which includes the saved data model's public collection settings. A raw GitHub or static CDN copy does not provide those settings. This template supports the default, case-sensitive `Aggregate` namespace.

## Initialize the SDK

1. In a GTM **Web** container, open **Templates → Tag Templates → New → Import** and import [template.tpl](template.tpl).
2. In the template editor, open **Permissions → Injects scripts**. Replace `https://analytics.example.com/*` with your Aggregate host, for example `https://stats.your-company.com/*`, then save the template. The host must match the **Aggregate script URL** used below.
3. Create an **Aggregate** tag with **Tag action** set to **Initialize SDK (automatic page view)** and fill in:

   | Field | Example | Purpose |
   | --- | --- | --- |
   | Aggregate script URL | `https://analytics.example.com/aggregate.js` | Configured SDK route; `/aggregate.js?min=1` and deployment path prefixes are supported. |
   | Collector endpoint | `https://analytics.example.com/api/receive` | HTTPS ingestion URL for your installation. |
   | Public website token | Your registered website's token | Identifies the website receiving events. |

4. Fire this tag early, for example with **Initialization – All Pages**. Use one initialization tag and one endpoint/token configuration per page.

The template adds URL-encoded `endpoint` and `token` query parameters to the script URL. Enter the base SDK URL, optionally with `?min=1`; do not add configuration parameters yourself. The public token is visible in the script request URL.

The SDK automatically sends the initial page view, waiting for `DOMContentLoaded` when necessary. Use this initialization tag as the only SDK loader and configure the endpoint and token through its fields. No additional initial page-view tag is needed. Inline `Aggregate.endpoint` or `Aggregate.websiteToken` settings take precedence over the template's URL configuration.

GTM caches script injection by the complete configured URL, so repeated initialization with the same settings shares one load. Changing the URL, endpoint, or token creates a different load; keep the configuration stable throughout the page.

## Send events

Create another **Aggregate** tag with **Tag action** set to **Send event**. Set a fixed event name, such as `signup_click`, add any event properties, and choose the event's trigger.

Under **Advanced Settings → Tag Sequencing**, select the initialization tag as the setup tag and enable **Don't fire this tag if the setup tag fails or is paused**. This makes the event wait for SDK loading; an early initialization trigger alone does not guarantee an asynchronous script has finished. The initialization cache allows the same setup tag to be reused.

The event action calls `window.Aggregate.emit(eventName, properties)`, omitting the properties argument when none are configured. It requires the SDK to be initialized and fails if the method is missing or returns `false`.

- Event names must match `[A-Za-z][A-Za-z0-9_.:-]{0,99}`: at most 100 characters, with no spaces. Use an approved taxonomy rather than names assembled from user input.
- Properties are optional, with at most 50 unique keys matching `[A-Za-z][A-Za-z0-9_.-]{0,63}`. Reserved prototype names are rejected; dots are literal characters.
- Values must be strings, finite numbers, booleans, or `null`. Nested objects and arrays are unsupported. Use GTM variables to preserve numeric and boolean types; text such as `"42"` remains a string.

The SDK and server apply the data model's consent, type, and collection filters. A property accepted by the template can still be omitted by those filters. See the [SDK tracking guide](https://github.com/Subschema-LLC/aggregate/blob/master/docs/TRACKING.md) for property limits and configuration. This template does not expose the SDK's optional goal argument.

## Consent and permissions

Initialization leaves Aggregate's consent state unchanged; a fresh SDK starts with unknown consent and anonymous tracking. This template does not map GTM consent settings or grant enhanced consent. Connect your consent manager to Aggregate's consent API as described in the SDK documentation. Anonymous page views and named events can continue after rejection, subject to the server's collection rules.

The script permission ships with the example pattern `https://analytics.example.com/*`; replace the host with your installation's host during setup. GTM requires HTTPS, a hostname, and a path pattern; a hostname consisting only of `*` is invalid. You can narrow the path to `/aggregate.js*`, or `/metrics/aggregate.js*` for a deployment under `/metrics`. Keep the trailing `*` to allow the SDK configuration query parameters. Changing the tag's script URL does not update its template permission.

The template also reads and executes `Aggregate.emit`; console logging is restricted to GTM preview/debug mode and requires the **Log failures to the console** checkbox.

## Verify before publishing

Run the imported template's tests in GTM, then use **Preview** to verify initialization and event sequencing. Confirm that the SDK loads once for a consistent configuration and that the initial page view is not duplicated.

Inspect `/api/receive` requests in browser DevTools, including response bodies. A successful GTM tag means the SDK loaded or accepted the event call; it does not confirm server ingestion. An HTTP 202 response can represent recorded data or intentionally ignored collection, and enhanced events may require a running server worker.

For local regression checks with Node.js 18 or later:

```sh
node --test tests/template.test.mjs
```

These tests use mocked GTM APIs. GTM's **Tests** tab and **Preview** remain necessary to verify the actual sandbox, permissions, deployment, and ingestion.

## Repository and releases

- [template.tpl](template.tpl): template fields, sandboxed code, permissions, and GTM tests.
- [tests/template.test.mjs](tests/template.test.mjs): local regression tests.
- [metadata.yaml](metadata.yaml): Community Template Gallery release history.

Before publishing to the Community Template Gallery, commit the tested template, then add a `versions` entry in `metadata.yaml` with that commit SHA and release notes. The SHA must identify the version intended for publication. Keep the newest entry first and preserve release history.
